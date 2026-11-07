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

ROOT = Path(__file__).resolve().parents[2]
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
  local node = manager.graph.nodes['obsidian-tools.nvim']
  assert((node ~= nil) == selected)
  assert((package.loaded.obsidian_tools ~= nil) == selected)
  assert((vim.fn.exists(':ObsidianTools') == 2) == selected)
  assert((vim.fn.maparg(' OO', 'n') ~= '') == selected)
  local paths = require('plugin_tools.util').runtime_paths()
  local directory = node and node.dir or require('utils.platform').dev_plugin_root() .. '/obsidian-tools.nvim'
  assert(vim.list_contains(paths, directory) == selected)
  if selected then
    assert(manager.states['obsidian-tools.nvim'].phase == 'ready')
    assert(node.opts.workspaces[1].path == vim.env.PROJECT_PLUGIN_VAULT)
    assert(node.opts.notes_subdir == 'notes')
  end
  assert(manager.graph.nodes['image-tools.nvim'].opts.insert.directory == (selected and 'assets/imgs' or 'Figures'))
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, string.char(10)))
end
local function finish(ok, err)
  vim.fn.writefile({ok and 'PASS' or err}, vim.env.PROJECT_PLUGIN_RESULT)
  vim.cmd(ok and 'qa!' or 'cquit 1')
end
local function await(predicate, next_step)
  local deadline = vim.uv.hrtime() + 5e9
  local function poll()
    local ok, err = xpcall(function()
      if predicate() then
        next_step()
      else
        assert(vim.uv.hrtime() < deadline, 'Obsidian menu interaction timed out')
        vim.defer_fn(poll, 10)
      end
    end, debug.traceback)
    if not ok then finish(false, err) end
  end
  vim.schedule(poll)
end
local function menu_check()
  local origin = vim.api.nvim_get_current_win()
  local dispatched, menu = false, nil
  require('obsidian_tools').refresh = function() dispatched=true end
  local original_select = vim.ui.select
  vim.ui.select = function(items, opts, callback)
    assert(opts.prompt == 'Obsidian Commands')
    assert(vim.list_contains(items, 'refresh'))
    menu = original_select(items, opts, callback)
    return menu
  end
  local function open(stage, next_step)
    vim.cmd.ObsidianTools()
    await(function()
      return menu and not menu.closed and vim.api.nvim_get_current_win() == menu.input_win
        and vim.api.nvim_get_mode().mode:sub(1, 1) == 'i'
    end, function()
      vim.cmd.redraw()
      local rows = {}
      for row = 1, vim.o.lines do
        local line = {}
        for col = 1, vim.o.columns do line[#line+1] = vim.fn.screenstring(row, col) end
        rows[#rows+1] = table.concat(line)
      end
      local screen = table.concat(rows, string.char(10))
      assert(screen:find('Obsidian Commands', 1, true), 'Menu title was not rendered')
      assert(screen:find(menu:current(), 1, true), 'Selected command was not rendered')
      vim.fn.writefile({stage}, vim.env.PROJECT_PLUGIN_STAGE)
      next_step()
    end)
  end
  open('cancel', function()
    await(function() return menu.closed and vim.api.nvim_get_current_win() == origin end, function()
      assert(not dispatched, 'Cancelling must not run a command')
      open('choose', function()
        await(function() return dispatched and menu.closed end, function()
          assert(vim.api.nvim_get_current_win() == origin)
          vim.ui.select = original_select
          check()
          finish(true)
        end)
      end)
    end)
  end)
end
vim.api.nvim_create_autocmd('User', {pattern='ConfigReady', once=true, callback=function()
  vim.defer_fn(function()
    local ok, err = xpcall(function()
      check()
      if vim.env.PROJECT_PLUGIN_SELECTED == '1' then menu_check() else finish(true) end
    end, debug.traceback)
    if not ok then finish(false, err) end
  end, 50)
end})
""")
    for selected, outside in ((False, False), (True, False), (True, True)):
        manifest.write_text("""
return {{id='obsidian-tools.nvim', opts={workspaces={{name='Fixture', path=vim.env.PROJECT_PLUGIN_VAULT}}}}}
""" if selected else "return {}")
        result = temp / f"result-{selected}-{outside}"
        stage_file = temp / f"stage-{selected}-{outside}"
        env = dict(os.environ, TERM="xterm-256color", NVIM_CONFIG_ROOT=str(ROOT),
                   NVIM_TEST_TMP=str(temp), NVIM_TEST_SCENARIO="writing", NVIM_SMOKE_TEST="1",
                   NVIM_TEST_ENABLE_THIRD_PARTY="0", XDG_CACHE_HOME=str(temp / "cache"),
                   XDG_STATE_HOME=str(temp / "state"), NVIM_LOG_FILE=str(temp / "nvim.log"),
                   NVIM_PLUGIN_LOCKFILE=str(lockfile), PROJECT_PLUGIN_SELECTED="1" if selected else "0",
                   PROJECT_PLUGIN_VAULT=str(project), PROJECT_PLUGIN_FILE=str(manifest),
                   PROJECT_PLUGIN_RESULT=str(result), PROJECT_PLUGIN_PROBE=str(probe),
                   PROJECT_PLUGIN_STAGE=str(stage_file))
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 110, 0, 0))
        process = subprocess.Popen([
            "nvim", "-n", "-i", "NONE", "--cmd",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua'); "
            "vim.secure.read=function(path) assert(path==vim.env.PROJECT_PLUGIN_FILE); "
            "return table.concat(vim.fn.readfile(path), string.char(10)) end; dofile(vim.env.PROJECT_PLUGIN_PROBE)",
            "-u", str(ROOT / "init.lua"), str(sample),
        ], cwd=temp if outside else project / "nested", env=env, stdin=slave, stdout=slave, stderr=slave)
        os.close(slave)
        output = bytearray()
        handled = set()
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
                stage = stage_file.read_text().strip() if stage_file.exists() else ""
                if stage and stage not in handled:
                    os.write(master, {"cancel": b"\x1b", "choose": b"refresh\r"}[stage])
                    handled.add(stage)
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
