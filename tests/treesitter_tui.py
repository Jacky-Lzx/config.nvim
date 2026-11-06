#!/usr/bin/env python3
"""Exercise the configured independent runtime with actual terminal input."""
import errno
import fcntl
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

root = Path(__file__).resolve().parents[1]
actions = {
    "lua": b"ilocal value = 1\x1b",
    "markdown": b" tmr",
    "markdown_edit": b"ggA edited\x1b",
    "tex": b"0f1r2",
}
with tempfile.TemporaryDirectory(prefix="treesitter-runtime-") as directory:
    temp = Path(directory)
    shutil.copyfile(root / "plugin-tools-lock.json", temp / "plugin-tools-lock.json")
    env = dict(os.environ, TERM="xterm-256color", NVIM_CONFIG_ROOT=str(root),
               NVIM_TEST_TMP=directory, NVIM_TEST_SCENARIO="writing", NVIM_SMOKE_TEST="1",
               XDG_STATE_HOME=directory + "/state", XDG_CACHE_HOME=directory + "/cache",
               NVIM_LOG_FILE=directory + "/nvim.log", NVIM_PLUGIN_LOCKFILE=directory + "/plugin-tools-lock.json",
               TREESITTER_TUI_RESULT=directory + "/result", TREESITTER_TUI_STAGE=directory + "/stage")
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 36, 140, 0, 0))
    process = subprocess.Popen([
        "nvim", "-n", "-i", "NONE", "--cmd", "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua')",
        "-u", str(root / "init.lua"), "-c", "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/treesitter_tui.lua')",
    ], cwd=root, env=env, stdin=slave, stdout=slave, stderr=slave)
    os.close(slave)
    output, handled = bytearray(), set()
    deadline = time.monotonic() + 30
    try:
        while process.poll() is None and time.monotonic() < deadline:
            if select.select([master], [], [], 0.02)[0]:
                try:
                    output.extend(os.read(master, 65536))
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
            stage_file = temp / "stage"
            stage = stage_file.read_text().strip() if stage_file.exists() else ""
            if stage in actions and stage not in handled:
                os.write(master, actions[stage])
                handled.add(stage)
        if process.poll() is None:
            process.kill()
        process.wait()
        result_file = temp / "result"
        result = result_file.read_text() if result_file.exists() else "Timed out; stages: " + repr(handled)
        assert process.returncode == 0 and result.startswith("PASS"), result + "\n" + output.decode(errors="replace")[-5000:]
        print(result.strip())
    finally:
        if process.poll() is None:
            process.kill()
        process.wait()
        os.close(master)
