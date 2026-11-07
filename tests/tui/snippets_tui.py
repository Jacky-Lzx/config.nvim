"""Exercise native collections through the configured terminal without a legacy engine."""

import fcntl
import json
import os
import sys
from pathlib import Path
import pty
import select
import shutil
import struct
import subprocess
import tempfile
import termios
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from support.processes import spawn, stop
from support.artifacts import workspace, Transcript, record_stage


root = Path(__file__).resolve().parents[2]
with workspace(prefix="configured-snippets-") as temporary:
    task = Path(temporary)
    shutil.copy2(root / "plugin-tools-lock.json", task / "plugin-tools-lock.json")
    env = dict(
        os.environ,
        TERM="xterm-256color",
        NVIM_CONFIG_ROOT=str(root),
        NVIM_SMOKE_TEST="1",
        NVIM_TEST_SCENARIO="writing",
        NVIM_SNIPPET_STATE=str(task / "state.json"),
        NVIM_PLUGIN_LOCKFILE=str(task / "plugin-tools-lock.json"),
        NVIM_LOG_FILE=str(task / "nvim.log"),
        XDG_CACHE_HOME=str(task / "cache"),
        XDG_STATE_HOME=str(task / "state"),
    )
    (task / "trial.md").write_text("")
    primary, secondary = pty.openpty()
    fcntl.ioctl(secondary, termios.TIOCSWINSZ, struct.pack("HHHH", 36, 120, 0, 0))
    child = spawn(
        [
            "nvim",
            "-i",
            "NONE",
            "--cmd",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua')",
            "-u",
            str(root / "init.lua"),
            "-c",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/tui/snippets_tui.lua')",
            str(task / "trial.md"),
        ],
        cwd=root,
        env=env,
        stdin=secondary,
        stdout=secondary,
        stderr=secondary,
        start_new_session=True,
    )
    os.close(secondary)
    output, states, tail = Transcript(), [], b""

    def send(keys):
        os.write(primary, keys)

    def drain():
        global tail
        data = os.read(primary, 65536)
        output.extend(data)
        stream = tail + data
        replies = {
            b"\x1b[5n": b"\x1b[0n",
            b"\x1b[6n": b"\x1b[1;1R",
            b"\x1b[c": b"\x1b[?1;2c",
            b"\x1b[>c": b"\x1b[>0;1;0c",
            b"\x1b[?u": b"\x1b[?0u",
        }
        for which, color in ((b"10", b"dddd/dddd/dddd"), (b"11", b"0000/0000/0000")):
            for end in (b"\x07", b"\x1b\\"):
                replies[b"\x1b]" + which + b";?" + end] = (
                    b"\x1b]" + which + b";rgb:" + color + end
                )
        for query, reply in replies.items():
            at = stream.find(query)
            while at >= 0:
                if at + len(query) > len(tail):
                    send(reply)
                at = stream.find(query, at + 1)
        tail = stream[-32:]

    def wait(predicate, label):
        record_stage(label)
        deadline, latest = time.monotonic() + 5, None
        while time.monotonic() < deadline:
            if select.select([primary], [], [], 0.01)[0]:
                try:
                    drain()
                except OSError:
                    break
            try:
                latest = json.loads((task / "state.json").read_text())
            except (FileNotFoundError, json.JSONDecodeError):
                continue
            assert not latest["errors"], latest
            if predicate(latest):
                states.append(label)
                return latest
        raise AssertionError(f"{label}: {latest}; tail={output[-1600:]!r}")

    def reset(filetype="markdown"):
        send(b"\x1b")
        wait(lambda s: s["mode"] == "n", "normal")
        send((":lua snippet_config_reset('" + filetype + "')\r").encode())
        wait(
            lambda s: (
                s["lines"] == [""] and s["mode"] == "n" and s["filetype"] == filetype
            ),
            "fresh " + filetype,
        )

    def expand(trigger):
        send(b"i" + trigger.encode())
        wait(lambda s: s["menu"] and s.get("selected") == trigger, trigger + " menu")
        send(b"\t")

    try:
        initial = wait(
            lambda s: s["mode"] == "n" and s["engine"] == "snippet-tools", "startup"
        )
        assert not initial["loaded"], "Opening Markdown eagerly loaded snippet runtime"
        send(b"ibold")
        wait(
            lambda s: s["menu"] and s.get("selected") == "bold",
            "native completion menu",
        )
        send(b"\t")
        wait(
            lambda s: s["mode"] == "s" and "**BOLD**" in s["screen"],
            "rendered native field",
        )
        send(b"text\x1bl!")
        wait(lambda s: s["lines"] == ["**text**!"], "native Alt-l")

        reset()
        send(b"itable2x2 ")
        wait(
            lambda s: (
                s["mode"] == "s"
                and s["lines"][:3] == ["| 1 | 2 |", "| - | - |", "| 3 | 4 |"]
            ),
            "generated table selection",
        )
        send(b"A\x1blB\x1blC\x1blD\x1bl!")
        wait(
            lambda s: s["lines"] == ["| A | B |", "| - | - |", "| C | D |", "!"],
            "table input burst",
        )

        reset()
        send(b"imkx\x1bl!")
        wait(lambda s: s["lines"] == ["$x$!"], "native math single expansion")

        reset("lua")
        expand("req")
        send(b"pkg.module\x1bl")
        wait(
            lambda s: (
                s["lines"] == ['local module = require("pkg.module")']
                and s["mode"] == "s"
            ),
            "Lua dynamic local name",
        )
        send(b"Alias\x1bl!")
        wait(
            lambda s: s["lines"] == ['local Alias = require("pkg.module")!'],
            "editable Lua dynamic field",
        )

        reset("python")
        expand("fras")
        send(b"pathlib\x1blPath\x1blP\x1bl!")
        wait(
            lambda s: s["lines"] == ["from pathlib import Path as P!"],
            "Python import field burst",
        )

        reset("rust")
        expand("hello")
        send(b"!")
        wait(
            lambda s: s["lines"] == ['println!("Hello world");!'],
            "Rust native expansion",
        )

        reset("typst")
        expand("figure")
        send(b"my_plot.png\x1blCaption\x1bl!")
        wait(
            lambda s: (
                s["lines"]
                == [
                    '#figure(image("./Figures/my_plot.png", width: 80%), caption: [Caption]) <fig:my_plot>!'
                ]
            ),
            "Typst computed figure label",
        )

        reset("systemverilog")
        expand("for")
        send(b"index\x1bl10\x1blbody\x1bl!")
        state = wait(
            lambda s: (
                s["lines"]
                == [
                    "for (index= 0; index < 10; index = index + 1) begin",
                    "  body!",
                    "end",
                ]
            ),
            "Verilog mirror burst",
        )
        assert not state["legacy_loaded"], "Native language snippets loaded LuaSnip"

        reset()
        send(b":SnippetToolsReload\r")
        wait(lambda s: s["mode"] == "n", "native collections reloaded")
        expand("bold")
        wait(lambda s: s["mode"] == "s", "native field after reload")
        send(b"native\x1bl!")
        state = wait(
            lambda s: s["lines"] == ["**native**!"], "native field input after reload"
        )
        assert not state["legacy_loaded"]

        reset()
        send(b"i#3 Title")
        wait(lambda s: s["lines"] == ["### Title"], "native heading burst")
        print(f"Configured snippet PTY: {len(states)} intermediate states passed")
    finally:
        if child.poll() is None:
            # Neovim can query DA1 while stopping the TUI. Keep servicing the
            # terminal until it exits instead of blocking in wait().
            send(b"\x1c\x0e:qa!\r")
            deadline = time.monotonic() + 3
            while child.poll() is None and time.monotonic() < deadline:
                if select.select([primary], [], [], 0.01)[0]:
                    try:
                        drain()
                    except OSError:
                        break
            if child.poll() is None:
                stop(child)
            child.wait(timeout=3)
        os.close(primary)
