#!/usr/bin/env python3
"""Run a Neovim integration check with a real terminal UI and bounded lifetime."""

import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import signal
import struct
import subprocess
import sys
import termios
import time

from processes import spawn, stop
from paths import test_path
from tui_cases import FILES


def main():
    root = Path(os.environ["NVIM_CONFIG_ROOT"])
    case = sys.argv[1]
    env = dict(os.environ, NVIM_STARTUP_CASE=case)
    if case == "completion_policy":
        env["NVIM_TEST_SCENARIO"] = "writing"
    if case == "python_environment":
        env["NVIM_TEST_SCENARIO"] = "python_environment"
    if case == "native_utilities":
        env["NVIM_TEST_SCENARIO"] = "lua"
    if case.startswith("image_"):
        env["NVIM_TEST_SCENARIO"] = "writing"
    if case in (
        "notifications",
        "notification_picker",
        "ui_tools",
        "completion_input",
        "bars",
        "folding",
        "toolchain",
        "annotations",
    ):
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
    result = Path(env["NVIM_TEST_TMP"]) / ("lifecycle-startup-" + case + ".log")
    if result.exists():
        result.unlink()
    env["NVIM_STARTUP_RESULT"] = str(result)
    env["TERM"] = "xterm-256color"
    master, slave = pty.openpty()
    fcntl.ioctl(
        slave,
        termios.TIOCSWINSZ,
        struct.pack(
            "HHHH", 40, 160 if case in ("ui_tools", "bars", "folding") else 120, 0, 0
        ),
    )
    test_file = FILES[case]
    command = [
        "nvim",
        "-i",
        "NONE",
        "--cmd",
        "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua')",
        "-u",
        str(root / "init.lua"),
        "-c",
        "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/"
        + test_path(test_file).relative_to(root).as_posix()
        + "')",
    ]
    if case == "markdown_direct":
        env["NVIM_TEST_MARKDOWN_DIRECT"] = "1"
        document = Path(env["NVIM_TEST_TMP"]) / "first.md"
        document.write_text("# Demand Markdown\n\nplain source\n\n- first\n- second\n")
        command.append(str(document))
    process = spawn(
        command,
        env=env,
        stdin=slave,
        stdout=slave,
        stderr=slave,
        start_new_session=True,
    )
    os.close(slave)
    keymap_actions = {
        "prefix": b" ",
        "subgroup": b"s",
        "hint_cancel": b"\x1b",
        "confirm": b"\r",
        "visual_cancel": b"\x1b",
        "visual_escape": b"\x1b",
        "operator_prefix": b"d",
        "object_prefix": b"i",
        "object_apply": b"(",
        "insert_register": b"i\x12",
        "insert_register_apply": b"z",
        "leave_insert": b"\x1b",
        "command_register": b":\x12",
        "command_register_apply": b"z",
        "command_cancel": b"\x1b",
    }
    annotation_actions = {
        "insert": b"3GA TODO: live #abcdef",
        "burst": b" " + b"x" * 200 + b" #00ff00",
        "normal": b"\x1b",
    }
    task_actions = {
        "command": b"\x15printf 'src/failure.c:2:3: error: demo\\n'\r",
        "jump": b"\r",
        "terminal_input": b"printf 'TASKS_PTY_OK\\n'\r",
        "list_close": b"q",
        "args_normal": bytes([29]),
        "args_close": b"q",
        "task_choice": b"Python: run file\r",
        "args": b"'hello world' \"\"\r",
    }
    output = bytearray()
    handled = set()
    toolchain_actions = {
        "plan": b"q",
        "install": b":ConfigToolsInstall\r",
        "tasks": b"\r",
        "retry": b"r",
        "close": b"q",
    }
    deadline = time.monotonic() + (50 if case == "python_environment" else 30)
    try:
        while process.poll() is None and time.monotonic() < deadline:
            ready, _, _ = select.select([master], [], [], 0.1)
            if ready:
                try:
                    chunk = os.read(master, 65536)
                    if not chunk:
                        break
                    output.extend(chunk)
                except OSError:
                    break
            if case == "health":
                stage_file = Path(env["NVIM_TEST_TMP"], "health-stage")
                lines = (
                    stage_file.read_text().splitlines() if stage_file.exists() else []
                )
                if len(lines) == 2 and lines[0] not in handled:
                    # Lua notation is converted only here; input goes through the PTY.
                    keys = json.loads(lines[1]).replace("<CR>", "\r")
                    os.write(master, keys.encode())
                    handled.add(lines[0])
            elif case == "python_environment":
                stage_file = Path(env["NVIM_TEST_TMP"], "python-stage")
                stage = stage_file.read_text().strip() if stage_file.exists() else ""
                actions = {
                    "open": b" cv",
                    "choose": b"chosen\r",
                    "open_other": b" cv",
                    "cancel": b"\x1b",
                }
                if stage in actions and stage not in handled:
                    os.write(master, actions[stage])
                    handled.add(stage)
            elif case == "tasks":
                stage_file = Path(env["NVIM_TEST_TMP"], "tasks-stage")
                lines = (
                    stage_file.read_text().splitlines() if stage_file.exists() else []
                )
                stage = lines[0] if lines else ""
                if stage and stage not in handled:
                    data = (
                        json.loads(lines[1]).encode()
                        if len(lines) == 2
                        else task_actions.get(stage)
                    )
                    if data is not None:
                        os.write(master, data)
                        handled.add(stage)
            elif case in ("motion", "editing_input", "markdown_tools"):
                stage_file = Path(
                    env["NVIM_TEST_TMP"],
                    "markdown-stage"
                    if case == "markdown_tools"
                    else "editing-stage"
                    if case == "editing_input"
                    else "motion-stage",
                )
                stage = (
                    stage_file.read_text().splitlines() if stage_file.exists() else []
                )
                if len(stage) == 2 and stage[0] not in handled:
                    # Lua observes typed-key consumption and waits for the result.
                    os.write(master, json.loads(stage[1]).encode())
                    handled.add(stage[0])
            elif case == "nested_keymaps":
                directory = Path(env["NVIM_TEST_TMP"])
                stage_file = directory / "stage"
                stage = stage_file.read_text().strip() if stage_file.exists() else ""
                if stage and stage not in handled:
                    resize = directory / "resize"
                    if resize.exists():
                        columns = int(resize.read_text())
                        resize.unlink()
                        fcntl.ioctl(
                            master,
                            termios.TIOCSWINSZ,
                            struct.pack("HHHH", 40, columns, 0, 0),
                        )
                        os.kill(process.pid, signal.SIGWINCH)
                    os.write(master, (directory / "input").read_bytes())
                    (directory / "ack").write_text(stage)
                    handled.add(stage)
            elif case == "keymaps":
                stage_file = Path(env["NVIM_TEST_TMP"], "keymap-stage")
                lines = (
                    stage_file.read_text().splitlines() if stage_file.exists() else []
                )
                stage = lines[0] if lines else ""
                if stage and stage not in handled:
                    data = (
                        json.loads(lines[1]).encode()
                        if len(lines) == 2
                        else keymap_actions.get(stage)
                    )
                    if data is not None:
                        os.write(master, data)
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
            stop(process)
            process.wait()
            print("Terminal check timed out: " + case, file=sys.stderr)
            plain = re.sub(
                r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\)|[()#][0-9A-Z]|[@-_])",
                "",
                output.decode(errors="replace"),
            )
            print(plain[-4000:], file=sys.stderr)
            if result.exists():
                print(result.read_text(errors="replace"), end="", file=sys.stderr)
            return 1
    finally:
        if process.poll() is None:
            stop(process)
        process.wait()
        os.close(master)
    if result.exists():
        print(result.read_text(errors="replace"), end="")
    else:
        print("Terminal check produced no result: " + case, file=sys.stderr)
        return 1
    return 0 if process.returncode == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
