"""Verify trusted project selection against actual configured Obsidian startup."""
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

ROOT = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="nvim-project-plugins-") as temporary:
    temp = Path(temporary).resolve()
    project = temp / "vault"
    (project / ".obsidian").mkdir(parents=True)
    (project / "nested").mkdir()
    sample = project / "nested" / "sample.md"
    sample.write_text("# Project selection\n")
    manifest = project / ".nvim-plugins.lua"
    lockfile = temp / "plugins.json"
    shutil.copyfile(ROOT / "plugin-tools-lock.json", lockfile)
    probe = temp / "probe.lua"
    probe.write_text("""
local function check()
  local selected = vim.env.PROJECT_PLUGIN_SELECTED == '1'
  local manager = require('config.plugins').manager
  local node = manager.graph.nodes['obsidian.nvim']
  assert((node ~= nil) == selected)
  assert((package.loaded.obsidian ~= nil) == selected)
  assert((vim.fn.exists(':Obsidian') == 2) == selected)
  assert((vim.fn.maparg(' OO', 'n') ~= '') == selected)
  local paths = require('plugin_tools.util').runtime_paths()
  local directory = node and node.dir or vim.fn.stdpath('data') .. '/plugin-tools/obsidian.nvim'
  assert(vim.list_contains(paths, directory) == selected)
  if selected then
    assert(manager.states['obsidian.nvim'].phase == 'ready')
    assert(node.opts.workspaces[1].path == vim.env.PROJECT_PLUGIN_VAULT)
    assert(node.opts.notes_subdir == 'notes')
  end
  assert(manager.graph.nodes['image-tools.nvim'].opts.insert.directory == (selected and 'assets/imgs' or 'Figures'))
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, string.char(10)))
end
vim.api.nvim_create_autocmd('User', {pattern='ConfigReady', once=true, callback=function()
  vim.defer_fn(function()
    local ok, err = xpcall(check, debug.traceback)
    vim.fn.writefile({ok and 'PASS' or err}, vim.env.PROJECT_PLUGIN_RESULT)
    vim.cmd(ok and 'qa!' or 'cquit 1')
  end, 50)
end})
""")
    for selected in (False, True):
        manifest.write_text("""
return {{id='obsidian.nvim', opts={workspaces={{name='Fixture', path=vim.env.PROJECT_PLUGIN_VAULT}}}}}
""" if selected else "return {}")
        result = temp / f"result-{selected}"
        env = dict(os.environ, TERM="xterm-256color", NVIM_CONFIG_ROOT=str(ROOT),
                   NVIM_TEST_TMP=str(temp), NVIM_TEST_SCENARIO="writing", NVIM_SMOKE_TEST="1",
                   NVIM_TEST_ENABLE_THIRD_PARTY="0", XDG_CACHE_HOME=str(temp / "cache"),
                   XDG_STATE_HOME=str(temp / "state"), NVIM_LOG_FILE=str(temp / "nvim.log"),
                   NVIM_PLUGIN_LOCKFILE=str(lockfile), PROJECT_PLUGIN_SELECTED="1" if selected else "0",
                   PROJECT_PLUGIN_VAULT=str(project), PROJECT_PLUGIN_FILE=str(manifest),
                   PROJECT_PLUGIN_RESULT=str(result), PROJECT_PLUGIN_PROBE=str(probe))
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 110, 0, 0))
        process = subprocess.Popen([
            "nvim", "-n", "-i", "NONE", "--cmd",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/setup.lua'); "
            "vim.secure.read=function(path) assert(path==vim.env.PROJECT_PLUGIN_FILE); "
            "return table.concat(vim.fn.readfile(path), string.char(10)) end; dofile(vim.env.PROJECT_PLUGIN_PROBE)",
            "-u", str(ROOT / "init.lua"), str(sample),
        ], cwd=project / "nested", env=env, stdin=slave, stdout=slave, stderr=slave)
        os.close(slave)
        output = bytearray()
        try:
            deadline = time.monotonic() + 15
            while process.poll() is None and time.monotonic() < deadline:
                if select.select([master], [], [], 0.05)[0]:
                    try:
                        output.extend(os.read(master, 65536))
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                        break
            if process.poll() is None:
                raise AssertionError("Startup timed out\n" + output.decode(errors="replace")[-4000:])
            message = result.read_text() if result.exists() else "No startup result"
            assert process.returncode == 0 and message.startswith("PASS"), message + "\n" + output.decode(errors="replace")[-4000:]
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)
    print("PASS project PTY: Obsidian runtime, setup, commands, mappings and image defaults follow project selection")
