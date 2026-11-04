#!/usr/bin/env python3
"""Run a Neovim integration check with a real terminal UI and bounded lifetime."""

import fcntl
import os
from pathlib import Path
import pty
import select
import struct
import subprocess
import sys
import termios
import time


def main():
    root = Path(os.environ["NVIM_CONFIG_ROOT"])
    case = sys.argv[1]
    env = dict(os.environ, NVIM_LAZY_CASE=case)
    if case in ("notifications", "ui_tools", "completion_input", "bars", "folding", "toolchain"):
        # Isolate UI/adapter behavior from external AI servers disabled by setup.lua.
        env["NVIM_TEST_SCENARIO"] = "minimal"
    result = Path(env["NVIM_TEST_TMP"]) / ("lazy-startup-" + case + ".log")
    if result.exists():
        result.unlink()
    env["NVIM_LAZY_RESULT"] = str(result)
    env["TERM"] = "xterm-256color"
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 160 if case in ("ui_tools", "bars", "folding") else 120, 0, 0))
    test_file = {"notifications": "notifications_tui.lua", "ui_tools": "ui_tools_tui.lua", "bars": "bars_tui.lua", "folding": "folding_tui.lua", "completion_input": "completion_tui.lua", "keymaps": "keymaps_tui.lua", "toolchain": "toolchain_tui.lua"}.get(case, "lazy_startup.lua")
    command = [
        "nvim", "-i", "NONE",
        "--cmd", "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')",
        "-u", str(root / "init.lua"),
        "-c", "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/" + test_file + "')",
    ]
    process = subprocess.Popen(command, env=env, stdin=slave, stdout=slave, stderr=slave, start_new_session=True)
    os.close(slave)
    keymap_actions = {
        "prefix": b" ", "subgroup": b"s", "hint_cancel": b"\x1b", "picker": b" ?",
        "filter": b"Wrap", "confirm": b"\r", "visual_picker": b"vj ?",
        "visual_cancel": b"\x1b", "visual_escape": b"\x1b", "operator_prefix": b"d", "object_prefix": b"i", "object_apply": b"(",
        "insert_register": b"i\x12", "insert_register_apply": b"z", "leave_insert": b"\x1b",
        "command_register": b":\x12", "command_register_apply": b"z", "command_cancel": b"\x1b",
    }
    handled = set()
    toolchain_actions = {"plan": b"q", "install": b":ConfigToolsInstall\r", "tasks": b"\r", "retry": b"r", "close": b"q"}
    deadline = time.monotonic() + 30
    try:
        while process.poll() is None and time.monotonic() < deadline:
            ready, _, _ = select.select([master], [], [], 0.1)
            if ready:
                try:
                    if not os.read(master, 65536):
                        break
                except OSError:
                    break
            if case == "keymaps":
                stage_file = Path(env["NVIM_TEST_TMP"], "keymap-stage")
                stage = stage_file.read_text().strip() if stage_file.exists() else ""
                if stage in keymap_actions and stage not in handled:
                    os.write(master, keymap_actions[stage])
                    handled.add(stage)
            elif case == "toolchain":
                stage_file = Path(env["NVIM_TEST_TMP"], "toolchain-stage")
                stage = stage_file.read_text().strip() if stage_file.exists() else ""
                if stage in toolchain_actions and stage not in handled:
                    os.write(master, toolchain_actions[stage])
                    handled.add(stage)
        try:
            # PTYs can report EOF just before the child exit becomes observable.
            process.wait(timeout=max(0.1, deadline - time.monotonic()))
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            print("Terminal check timed out: " + case, file=sys.stderr)
            if result.exists():
                print(result.read_text(), end="", file=sys.stderr)
            return 1
    finally:
        if process.poll() is None:
            process.kill()
        process.wait()
        os.close(master)
    if result.exists():
        print(result.read_text(), end="")
    else:
        print("Terminal check produced no result: " + case, file=sys.stderr)
        return 1
    return 0 if process.returncode == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
