#!/usr/bin/env python3
"""Exercise actual native-diff rename and code actions in the configured terminal."""
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
plugins = Path(os.environ.get("NVIM_DEV_PLUGIN_ROOT", str(Path.home() / "Documents/Github/nvim_plugins")))
for case in ("rename", "actions"):
    with tempfile.TemporaryDirectory(prefix="nvim-native-" + case + "-") as directory:
        temp = Path(directory)
        shutil.copyfile(root / "lazy-lock.json", temp / "lock.json")
        env = dict(os.environ, TERM="xterm-256color", NVIM_CONFIG_ROOT=str(root),
                   NVIM_LAZY_LOCKFILE=str(temp / "lock.json"), LSP_NATIVE_CASE=case,
                   LSP_TOOLS_TEST_TMP=directory, LSP_TOOLS_ROOT=str(plugins / "lsp-tools.nvim"),
                   LSP_TOOLS_TUI="1", SELECTION_TOOLS_DIR=str(plugins / "selection-tools.nvim"),
                   GIT_TOOLS_DIR=str(plugins / "git-tools.nvim"),
                   SNACKS_DIR=str(Path.home() / ".local/share/nvim/lazy/snacks.nvim"),
                   XDG_CACHE_HOME=directory + "/cache", XDG_STATE_HOME=directory + "/state",
                   NVIM_LOG_FILE=directory + "/nvim.log")
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 140, 0, 0))
        process = subprocess.Popen(["nvim", "-n", "-i", "NONE", "-u", "NONE", "-c",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/lsp_native_tui.lua')"], cwd=root,
            env=env, stdin=slave, stdout=slave, stderr=slave)
        os.close(slave)
        output = bytearray()
        deadline = time.monotonic() + 90
        try:
            while process.poll() is None and time.monotonic() < deadline:
                if select.select([master], [], [], .05)[0]:
                    try:
                        output.extend(os.read(master, 65536))
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
            if process.poll() is None:
                process.kill()
            process.wait()
            result = temp / "result"
            report = result.read_text() if result.exists() else "No native diff test result"
            assert process.returncode == 0 and "passed" in report, report + "\n" + output.decode(errors="replace")[-4000:]
            print(report.strip())
        finally:
            if process.poll() is None:
                process.kill()
            process.wait()
            os.close(master)
