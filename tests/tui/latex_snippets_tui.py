"""Real configured PTY input, including rendered fields and native collection reload."""

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
with workspace(prefix="latex-snippets-") as temporary:
    task = Path(temporary)
    (task / "state/nvim").mkdir(parents=True)
    shutil.copy2(root / "plugin-tools-lock.json", task / "plugin-tools-lock.json")
    env = dict(
        os.environ,
        TERM="xterm-256color",
        NVIM_CONFIG_ROOT=str(root),
        NVIM_SMOKE_TEST="1",
        NVIM_TEST_SCENARIO="writing",
        NVIM_SNIPPET_STATE=str(task / "snapshot.json"),
        NVIM_PLUGIN_LOCKFILE=str(task / "plugin-tools-lock.json"),
        NVIM_LOG_FILE=str(task / "nvim.log"),
        XDG_CACHE_HOME=str(task / "cache"),
        XDG_STATE_HOME=str(task / "state"),
        SSH_CONNECTION="",
    )
    (task / "trial.tex").write_text("")
    primary, secondary = pty.openpty()
    fcntl.ioctl(secondary, termios.TIOCSWINSZ, struct.pack("HHHH", 36, 120, 0, 0))
    child = spawn(
        [
            os.environ.get("NVIM", "nvim"),
            "-i",
            "NONE",
            "--cmd",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua')",
            "-u",
            str(root / "init.lua"),
            "-c",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/tui/latex_snippets_tui.lua')",
            str(task / "trial.tex"),
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
        deadline, latest = time.monotonic() + 7, None
        while time.monotonic() < deadline:
            if select.select([primary], [], [], 0.01)[0]:
                try:
                    drain()
                except OSError:
                    break
            try:
                latest = json.loads((task / "snapshot.json").read_text())
            except (FileNotFoundError, json.JSONDecodeError):
                continue
            assert not latest["errors"], latest
            if predicate(latest):
                states.append(label)
                return latest
        raise AssertionError(f"{label}: {latest}; tail={output[-1600:]!r}")

    def reset(beamer=False):
        send(b"\x1c\x0e")  # Ctrl-\ Ctrl-N also exits Insert mode unambiguously.
        wait(lambda s: s["mode"] == "n", "normal")
        send(b":lua latex_snippet_reset(" + (b"true" if beamer else b"false") + b")\r")
        wait(
            lambda s: (
                s["mode"] == "n"
                and s["lines"]
                == (
                    [
                        "\\documentclass{beamer}",
                        "\\begin{document}",
                        "",
                        "\\end{document}",
                    ]
                    if beamer
                    else [""]
                )
            ),
            "fresh TeX",
        )

    def expand(trigger):
        send(b"i" + trigger.encode())
        wait(lambda s: s["menu"] and s.get("selected") == trigger, trigger + " menu")
        send(b"\t")

    try:
        initial = wait(
            lambda s: s["mode"] == "n" and s["engine"] == "snippet-tools",
            "cold TeX startup",
        )
        assert not initial["loaded"], "TeX opening eagerly loaded snippet runtime"
        expand("bf")
        wait(
            lambda s: (
                s["lines"] == ["\\textbf{}"]
                and s["mode"] == "i"
                and "" in s["screen"]
                and "" in s["screen"]
            ),
            "native field and distinct final-stop markers",
        )
        send(b"text\x1bl!")
        wait(
            lambda s: (
                s["lines"] == ["\\textbf{text}!"] and "\\textbf{text}!" in s["screen"]
            ),
            "rendered TeX wrapper",
        )

        reset()
        send(b"imkx\x1bl!")
        wait(lambda s: s["lines"] == ["\\( x \\)!"], "single TeX inline expansion")
        reset()
        send(b"i$xvec")
        wait(lambda s: s["lines"] == ["$\\vec{x}"], "math postfix through terminal")
        reset()
        send(b"i$x//y\x1bl!")
        wait(lambda s: s["lines"] == ["$\\frac{x}{y}!"], "postfix fraction field")

        reset()
        expand("equation")
        wait(
            lambda s: any("\\label{eq:}" in line for line in s["lines"]),
            "equation label",
        )
        send(b"\x1blx\x1bh\x1bj")
        wait(
            lambda s: s["lines"] == ["\\begin{equation*}", "  x", "\\end{equation*}"],
            "star removes label, preserves body",
        )
        send(b"\x1bk")
        wait(
            lambda s: (
                any("\\label{eq:}" in line for line in s["lines"])
                and s["lines"][1] == "  x"
            ),
            "reverse choice restores label",
        )

        reset()
        expand("figure")
        wait(
            lambda s: s["mode"] == "s" and s["selection"] == "H" and "" in s["screen"],
            "figure placement selection and choice marker",
        )
        send(b"\x1bj\x1bl7\x1blmy_figure.pdf\x1blCaption\x1bl!")
        wait(
            lambda s: (
                "  \\label{fig:my-figure}" in s["lines"]
                and s["lines"][-1] == "\\end{figure}!"
            ),
            "filename label linkage",
        )

        reset(True)
        expand("columns")
        wait(
            lambda s: (
                s["mode"] == "s" and s["selection"] == "49" and "0.49" in s["screen"]
            ),
            "rendered column width selection",
        )
        send(b"30\x1blLeft\x1blRight")
        wait(
            lambda s: (
                "  \\begin{column}{0.68\\linewidth}" in s["lines"]
                and "    Right" in s["lines"]
            ),
            "linked Beamer widths",
        )

        reset()
        send(b":SnippetToolsReload\r")
        wait(lambda s: s["mode"] == "n", "native TeX reload")
        expand("bf")
        wait(
            lambda s: s["lines"] == ["\\textbf{}"] and s["mode"] == "i",
            "native query after reload",
        )
        send(b"native\x1bl!")
        wait(
            lambda s: s["lines"] == ["\\textbf{native}!"],
            "native field navigation after reload",
        )
        print(f"Configured LaTeX PTY: {len(states)} intermediate states passed")
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
