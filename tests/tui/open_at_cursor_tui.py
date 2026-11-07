#!/usr/bin/env python3
"""Exercise configured go mappings with real terminal input and a harmless opener."""

import fcntl
import json
import os
from pathlib import Path
import pty
import select
import struct
import subprocess
import sys
import tempfile
import termios
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from support.processes import spawn, stop
from support.artifacts import workspace, Transcript, record_stage


root = Path(__file__).resolve().parents[2]
with workspace(prefix="nvim-open-", dir="/tmp") as temporary:
    temp = Path(temporary).resolve()
    backend = temp / "opener.py"
    backend.write_text(
        "import json, os, sys\n"
        "with open(os.environ['NVIM_TEST_OPEN_LOG'], 'a') as log:\n"
        "    log.write(json.dumps(sys.argv[1:]) + '\\n')\n"
    )
    (temp / "lock.json").write_bytes((root / "plugin-tools-lock.json").read_bytes())
    env = dict(
        os.environ,
        TERM="xterm-256color",
        NVIM_CONFIG_ROOT=str(root),
        NVIM_TEST_TMP=str(temp),
        NVIM_TEST_SCENARIO="minimal",
        NVIM_SMOKE_TEST="1",
        NVIM_PLUGIN_LOCKFILE=str(temp / "lock.json"),
        NVIM_TEST_OPEN_LOG=str(temp / "opened"),
        NVIM_OPEN_CMD=f"{sys.executable} {backend}",
        XDG_STATE_HOME=str(temp / "state"),
        XDG_CACHE_HOME=str(temp / "cache"),
        NVIM_LOG_FILE=str(temp / "nvim.log"),
    )
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))
    process = spawn(
        [
            "nvim",
            "-i",
            "NONE",
            "--cmd",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua')",
            "-u",
            str(root / "init.lua"),
            "-c",
            "luafile " + str(root / "tests/tui/open_at_cursor_tui.lua"),
        ],
        stdin=slave,
        stdout=slave,
        stderr=slave,
        env=env,
        start_new_session=True,
    )
    os.close(slave)
    output, handled = Transcript(), set()
    deadline = time.monotonic() + 25
    try:
        while process.poll() is None and time.monotonic() < deadline:
            ready, _, _ = select.select([master], [], [], 0.05)
            if ready:
                try:
                    output.extend(os.read(master, 65536))
                except OSError:
                    break
            stage = temp / "open-stage"
            if stage.exists():
                lines = stage.read_text().splitlines()
                if len(lines) == 2 and lines[0] not in handled:
                    os.write(master, json.loads(lines[1]).encode())
                    record_stage(lines[0])
                    handled.add(lines[0])
        process.wait(timeout=max(0.1, deadline - time.monotonic()))
    except subprocess.TimeoutExpired:
        raise AssertionError(
            "Configured go PTY timed out: " + output.decode(errors="replace")[-2000:]
        )
    finally:
        if process.poll() is None:
            stop(process)
        process.wait()
        os.close(master)
    result = temp / "open-result"
    assert result.exists(), output.decode(errors="replace")[-2000:]
    print(result.read_text(), end="")
    assert process.returncode == 0
