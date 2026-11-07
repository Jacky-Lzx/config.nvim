#!/usr/bin/env python3
"""Exercise configured workspace mappings and dashboard with physical PTY input."""

import errno
import fcntl
import os
import sys
from pathlib import Path
import pty
import select
import struct
import subprocess
import termios
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from support.processes import spawn, stop
from support.artifacts import workspace, Transcript, record_stage


def main():
    root = Path(os.environ["NVIM_CONFIG_ROOT"])
    directory = Path(os.environ["NVIM_TEST_TMP"]) / "workspace-tui"
    directory.mkdir(parents=True, exist_ok=True)
    for file in ("stage", "result"):
        (directory / file).unlink(missing_ok=True)
    env = dict(os.environ, TERM="xterm-256color", NVIM_NOTTYFAST="1")
    env.pop("NVIM_TEST_SCENARIO", None)
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 38, 140, 0, 0))
    setup = """lua vim.opt.rtp:prepend(vim.env.NVIM_CONFIG_ROOT); package.preload['config.selection'] = function() return {profiles={}, features={tasks=true,sessions=true}} end; dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua')"""
    process = spawn(
        [
            "nvim",
            "-i",
            "NONE",
            "--cmd",
            setup,
            "-u",
            str(root / "init.lua"),
            "-c",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/tui/workspace_tui.lua')",
        ],
        env=env,
        cwd=root,
        stdin=slave,
        stdout=slave,
        stderr=slave,
    )
    os.close(slave)
    actions = {
        "save_alpha": b" pw",
        "save_beta": b":WorkspaceSave BetaTargetWorkspace\r",
        "restore_alpha": b" ps",
        "search": b" pS",
        "query": b"BetaTargetWorkspace",
        "choose": b"\r",
        "delete_prompt": b" pD",
        "delete_filter": b"Delete",
        "delete_confirm": b"\r",
        "dashboard": b"s",
    }
    handled, output = set(), Transcript()
    deadline = time.monotonic() + 35
    try:
        while process.poll() is None and time.monotonic() < deadline:
            if select.select([master], [], [], 0.02)[0]:
                try:
                    output.extend(os.read(master, 65536))
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
            file = directory / "stage"
            stage = file.read_text().strip() if file.exists() else ""
            if stage in actions and stage not in handled:
                os.write(master, actions[stage])
                record_stage(stage)
                handled.add(stage)
        assert process.poll() is not None, "TUI timeout: " + repr(handled)
        result = (
            (directory / "result").read_text()
            if (directory / "result").exists()
            else "missing result"
        )
        assert process.returncode == 0 and result.startswith("PASS"), result
        print(result.strip())
    except Exception:
        print(output.decode(errors="replace")[-5000:])
        raise
    finally:
        if process.poll() is None:
            stop(process)
        process.wait()
        os.close(master)


if __name__ == "__main__":
    main()
