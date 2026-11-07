#!/usr/bin/env python3
"""Drive a declared Neovim scenario through an isolated real terminal."""

import fcntl
import os
from pathlib import Path
import pty
import select
import signal
import struct
import subprocess
import sys
import termios
import time

from artifacts import Transcript, record_stage
from paths import test_path
from processes import spawn, stop
from tui_cases import SCENARIOS
from tui_protocol import event


def main():
    root = Path(os.environ["NVIM_CONFIG_ROOT"])
    directory = Path(os.environ["NVIM_TEST_TMP"])
    name = sys.argv[1]
    scenario = SCENARIOS[name]
    env = dict(os.environ, NVIM_STARTUP_CASE=name, TERM="xterm-256color")
    for key, value in scenario.defaults.items():
        env.setdefault(key, value)
    env.update(scenario.env)
    if scenario.stage:
        (directory / scenario.stage.file).unlink(missing_ok=True)
    result = directory / ("lifecycle-startup-" + name + ".log")
    result.unlink(missing_ok=True)
    env["NVIM_STARTUP_RESULT"] = str(result)
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
        + test_path(scenario.file).relative_to(root).as_posix()
        + "')",
    ]
    if scenario.document:
        document = directory / scenario.document
        document.write_text(scenario.text)
        command.append(str(document))
    master, slave = pty.openpty()
    fcntl.ioctl(
        slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, scenario.columns, 0, 0)
    )
    process = spawn(command, env=env, stdin=slave, stdout=slave, stderr=slave)
    os.close(slave)
    output, handled = Transcript(), set()
    deadline = time.monotonic() + scenario.timeout
    record_stage("startup")
    try:
        while process.poll() is None and time.monotonic() < deadline:
            if select.select([master], [], [], 0.1)[0]:
                try:
                    chunk = os.read(master, 65536)
                    if not chunk:
                        break
                    output.extend(chunk)
                except OSError:
                    break
            pending = event(scenario.stage, directory, handled)
            if pending:
                stage, data, columns = pending
                if columns:
                    fcntl.ioctl(
                        master,
                        termios.TIOCSWINSZ,
                        struct.pack("HHHH", 40, columns, 0, 0),
                    )
                    os.kill(process.pid, signal.SIGWINCH)
                record_stage(stage)
                os.write(master, data)
                if scenario.stage.input_file:
                    (directory / "ack").write_text(stage)
                handled.add(stage)
        try:
            process.wait(timeout=max(0.1, deadline - time.monotonic()))
        except subprocess.TimeoutExpired:
            stop(process)
            print("Terminal check timed out: " + name, file=sys.stderr)
            print(output.path.with_suffix(".txt").read_text()[-4000:], file=sys.stderr)
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
        print("Terminal check produced no result: " + name, file=sys.stderr)
        return 1
    return 0 if process.returncode == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
