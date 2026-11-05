"""Real configured PTY input, including rendered fields and engine switching."""
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import shutil
import struct
import subprocess
import tempfile
import termios
import time

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix="latex-snippets-") as temporary:
    task = Path(temporary)
    (task / "state/nvim").mkdir(parents=True)
    shutil.copy2(root / "lazy-lock.json", task / "lazy-lock.json")
    env = dict(os.environ, TERM="xterm-256color", NVIM_CONFIG_ROOT=str(root), NVIM_SMOKE_TEST="1",
               NVIM_TEST_SCENARIO="writing", NVIM_SNIPPET_STATE=str(task / "snapshot.json"),
               NVIM_LAZY_LOCKFILE=str(task / "lazy-lock.json"), NVIM_LOG_FILE=str(task / "nvim.log"),
               XDG_CACHE_HOME=str(task / "cache"), XDG_STATE_HOME=str(task / "state"), SSH_CONNECTION="")
    (task / "trial.tex").write_text("")
    primary, secondary = pty.openpty()
    fcntl.ioctl(secondary, termios.TIOCSWINSZ, struct.pack("HHHH", 36, 120, 0, 0))
    child = subprocess.Popen([os.environ.get("NVIM", "nvim"), "-i", "NONE", "--cmd",
        "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')", "-u", str(root / "init.lua"),
        "-c", "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/latex_snippets_tui.lua')", str(task / "trial.tex")],
        cwd=root, env=env, stdin=secondary, stdout=secondary, stderr=secondary, start_new_session=True)
    os.close(secondary)
    output, states, tail = bytearray(), [], b""

    def send(keys):
        os.write(primary, keys)

    def drain():
        global tail
        data = os.read(primary, 65536)
        output.extend(data)
        stream = tail + data
        replies = {b"\x1b[5n": b"\x1b[0n", b"\x1b[6n": b"\x1b[1;1R", b"\x1b[c": b"\x1b[?1;2c",
                   b"\x1b[>c": b"\x1b[>0;1;0c", b"\x1b[?u": b"\x1b[?0u"}
        for which, color in ((b"10", b"dddd/dddd/dddd"), (b"11", b"0000/0000/0000")):
            for end in (b"\x07", b"\x1b\\"):
                replies[b"\x1b]" + which + b";?" + end] = b"\x1b]" + which + b";rgb:" + color + end
        for query, reply in replies.items():
            at = stream.find(query)
            while at >= 0:
                if at + len(query) > len(tail): send(reply)
                at = stream.find(query, at + 1)
        tail = stream[-32:]

    def wait(predicate, label):
        deadline, latest = time.monotonic() + 7, None
        while time.monotonic() < deadline:
            if select.select([primary], [], [], .01)[0]:
                try: drain()
                except OSError: break
            try: latest = json.loads((task / "snapshot.json").read_text())
            except (FileNotFoundError, json.JSONDecodeError): continue
            assert not latest["errors"], latest
            if predicate(latest):
                states.append(label)
                return latest
        raise AssertionError(f"{label}: {latest}; tail={output[-1600:]!r}")

    def reset(beamer=False):
        send(b"\x1c\x0e")  # Ctrl-\ Ctrl-N also exits Insert mode unambiguously.
        wait(lambda s: s["mode"] == "n", "normal")
        send(b":lua latex_snippet_reset(" + (b"true" if beamer else b"false") + b")\r")
        wait(lambda s: s["mode"] == "n" and s["lines"] == (
            ["\\documentclass{beamer}", "\\begin{document}", "", "\\end{document}"] if beamer else [""]), "fresh TeX")

    def expand(trigger):
        send(b"i" + trigger.encode())
        wait(lambda s: s["menu"] and s.get("selected") == trigger, trigger + " menu")
        send(b"\t")

    try:
        initial = wait(lambda s: s["mode"] == "n" and s["engine"] == "snippet-tools", "cold TeX startup")
        assert not initial["loaded"], "TeX opening eagerly loaded snippet runtime"
        expand("bf")
        wait(lambda s: s["lines"] == ["\\textbf{}"] and s["mode"] == "i" and "" in s["screen"] and "" in s["screen"], "native field and distinct final-stop markers")
        send(b"text\x1bl!")
        wait(lambda s: s["lines"] == ["\\textbf{text}!"] and "\\textbf{text}!" in s["screen"], "rendered TeX wrapper")

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
        wait(lambda s: any("\\label{eq:}" in line for line in s["lines"]), "equation label")
        send(b"\x1blx\x1bh\x1bj")
        wait(lambda s: s["lines"] == ["\\begin{equation*}", "  x", "\\end{equation*}"], "star removes label, preserves body")
        send(b"\x1bk")
        wait(lambda s: any("\\label{eq:}" in line for line in s["lines"]) and s["lines"][1] == "  x", "reverse choice restores label")

        reset()
        expand("figure")
        wait(lambda s: s["mode"] == "s" and s["selection"] == "H" and "" in s["screen"], "figure placement selection and choice marker")
        send(b"\x1bj\x1bl7\x1blmy_figure.pdf\x1blCaption\x1bl!")
        wait(lambda s: "  \\label{fig:my-figure}" in s["lines"] and s["lines"][-1] == "\\end{figure}!", "filename label linkage")

        reset(True)
        expand("columns")
        wait(lambda s: s["mode"] == "s" and s["selection"] == "49" and "0.49" in s["screen"], "rendered column width selection")
        send(b"30\x1blLeft\x1blRight")
        wait(lambda s: "  \\begin{column}{0.68\\linewidth}" in s["lines"] and "    Right" in s["lines"], "linked Beamer widths")

        reset()
        send(b":SnippetEngine luasnip\r")
        wait(lambda s: s["engine"] == "luasnip" and s["mode"] == "n", "legacy TeX switch")
        expand("bf")
        wait(lambda s: s["lines"] == ["\\textbf{}"] and s["mode"] == "i", "first legacy query loads collection")
        send(b"old\x1bl!")
        wait(lambda s: s["lines"] == ["\\textbf{old}!"] and not s["native"]["active"], "legacy field navigation")
        send(b"\x1c\x0e:SnippetEngineToggle\r")
        wait(lambda s: s["engine"] == "snippet-tools" and s["mode"] == "n", "native TeX restored")
        print(f"Configured LaTeX PTY: {len(states)} intermediate states passed")
    finally:
        if child.poll() is None:
            child.terminate()
            try: child.wait(timeout=3)
            except subprocess.TimeoutExpired:
                child.kill(); child.wait()
        os.close(primary)
