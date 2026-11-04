#!/usr/bin/env python3
"""Run a Neovim integration check with a real terminal UI and bounded lifetime."""

import fcntl
import json
import os
from pathlib import Path
import pty
import re
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
    if case.startswith("image_"):
        env["NVIM_TEST_SCENARIO"] = "writing"
    if case in ("notifications", "notification_picker", "ui_tools", "completion_input", "bars", "folding", "toolchain", "annotations"):
        # Isolate UI/adapter behavior from external AI servers disabled by setup.lua.
        env["NVIM_TEST_SCENARIO"] = "minimal"
    if case == "motion":
        env.setdefault("NVIM_TEST_SCENARIO", "minimal")
    if case == "motion":
        Path(env["NVIM_TEST_TMP"], "motion-stage").unlink(missing_ok=True)
    if case == "tasks":
        Path(env["NVIM_TEST_TMP"], "tasks-stage").unlink(missing_ok=True)
    if case == "annotations":
        Path(env["NVIM_TEST_TMP"], "annotations-stage").unlink(missing_ok=True)
    result = Path(env["NVIM_TEST_TMP"]) / ("lazy-startup-" + case + ".log")
    if result.exists():
        result.unlink()
    env["NVIM_LAZY_RESULT"] = str(result)
    env["TERM"] = "xterm-256color"
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 160 if case in ("ui_tools", "bars", "folding") else 120, 0, 0))
    test_file = {"tasks": "tasks_tui.lua", "motion": "motion_tui.lua", "notifications": "notifications_tui.lua", "notification_picker": "notification_picker_tui.lua", "ui_tools": "ui_tools_tui.lua", "annotations": "annotations_tui.lua", "bars": "bars_tui.lua", "folding": "folding_tui.lua", "completion_input": "completion_tui.lua", "copilot": "copilot_tui.lua", "keymaps": "keymaps_tui.lua", "toolchain": "toolchain_tui.lua"}.get(case, "image_loading_tui.lua" if case.startswith("image_") else "lazy_startup.lua")
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
        "filter": b"tw Wrap", "confirm": b"\r", "visual_picker": b"vj ?",
        "visual_cancel": b"\x1b", "visual_escape": b"\x1b", "operator_prefix": b"d", "object_prefix": b"i", "object_apply": b"(",
        "insert_register": b"i\x12", "insert_register_apply": b"z", "leave_insert": b"\x1b",
        "command_register": b":\x12", "command_register_apply": b"z", "command_cancel": b"\x1b",
    }
    annotation_actions = {"insert": b"3GA TODO: live #abcdef", "burst": b" " + b"x" * 200 + b" #00ff00", "normal": b"\x1b"}
    task_actions = {'prompt': b' mc', 'command': b"\x15printf 'src/failure.c:2:3: error: demo\\n'\r", 'manual_output': b' mo', 'quickfix': b' mq', 'jump': b'\r', 'terminal': b'\x1bi', 'terminal_input': b"printf 'TASKS_PTY_OK\\n'\r", 'terminal_hide': b'\x1bi', 'terminal_reopen': b'\x1bi', 'terminal_hide_again': b'\x1bi', 'rerun': b' mr', 'list': b' ot', 'list_close': b'q', 'args_normal': bytes([29]), 'args_close': b'q', 'select_task': b' or', 'task_choice': b'Python: run file\r', 'run_args': b' oa', 'args': b'\'hello world\' ""\r'}
    output = bytearray()
    handled = set()
    motion_sentinel_at = None
    toolchain_actions = {"plan": b"q", "install": b":ConfigToolsInstall\r", "tasks": b"\r", "retry": b"r", "close": b"q"}
    deadline = time.monotonic() + 30
    try:
        while process.poll() is None and time.monotonic() < deadline:
            if motion_sentinel_at is not None and time.monotonic() >= motion_sentinel_at:
                os.write(master, b"\x1b[24~")
                motion_sentinel_at = None
            ready, _, _ = select.select([master], [], [], 0.1)
            if ready:
                try:
                    chunk = os.read(master, 65536)
                    if not chunk:
                        break
                    output.extend(chunk)
                except OSError:
                    break
            if case == "tasks":
                stage_file = Path(env["NVIM_TEST_TMP"], "tasks-stage")
                stage = stage_file.read_text().strip() if stage_file.exists() else ""
                if stage in task_actions and stage not in handled:
                    os.write(master, task_actions[stage])
                    handled.add(stage)
            elif case == "motion":
                stage_file = Path(env["NVIM_TEST_TMP"], "motion-stage")
                stage = stage_file.read_text().splitlines() if stage_file.exists() else []
                if len(stage) == 2 and stage[0] not in handled:
                    os.write(master, json.loads(stage[1]).encode())
                    handled.add(stage[0])
                    motion_sentinel_at = time.monotonic() + 0.06
            elif case == "keymaps":
                stage_file = Path(env["NVIM_TEST_TMP"], "keymap-stage")
                stage = stage_file.read_text().strip() if stage_file.exists() else ""
                if stage in keymap_actions and stage not in handled:
                    os.write(master, keymap_actions[stage])
                    handled.add(stage)
            elif case == "annotations":
                stage_file = Path(env["NVIM_TEST_TMP"], "annotations-stage")
                stage = stage_file.read_text().strip() if stage_file.exists() else ""
                if stage in annotation_actions and stage not in handled:
                    os.write(master, annotation_actions[stage])
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
            plain = re.sub(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\)|[()#][0-9A-Z]|[@-_])", "", output.decode(errors="replace"))
            print(plain[-4000:], file=sys.stderr)
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
