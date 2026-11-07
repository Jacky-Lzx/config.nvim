"""Exercise project completion, active-field reload and directory isolation in a PTY."""

import errno
import fcntl
import os
import sys
from pathlib import Path
import pty
import select
import shutil
import struct
import subprocess
import tempfile
import termios
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from support.processes import spawn, stop


ROOT = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="nvim-project-snippets-") as temporary:
    temp = Path(temporary).resolve()
    project = temp / "project"
    (project / "nested").mkdir(parents=True)
    (project / ".nvim/snippets").mkdir(parents=True)
    sample = project / "sample.lua"
    sample.write_text("")
    manifest = project / ".nvim-plugins.lua"
    manifest.write_text(
        'return {{id="snippet-tools.nvim",opts={project={paths={".nvim/snippets"}}}}}'
    )
    snippets = project / ".nvim/snippets/lua.lua"
    snippets.write_text('return {{trigger="prx",body="project(${1:value})$0"}}')
    lockfile = temp / "plugins.json"
    shutil.copyfile(ROOT / "plugin-tools-lock.json", lockfile)
    probe = temp / "probe.lua"
    probe.write_text("""
local api, stage = vim.api, 'initial'
local function mark(value)
  stage = value
  vim.fn.writefile({value}, vim.env.PROJECT_SNIPPETS_STAGE)
end
local function check()
  if not vim.g.config_ready then return end
  local line, mode = api.nvim_get_current_line(), api.nvim_get_mode().mode
  if stage == 'initial' then
    assert(not package.loaded.snippet_tools, 'Project setup must remain lazy')
    assert(require('config.specs').project_root() == vim.env.PROJECT_SNIPPETS_ROOT)
    vim.cmd.cd(vim.env.NVIM_TEST_TMP)
    vim.b.completion_tools_sources = {'snippets'}
    vim.keymap.set('i', '<F8>', function()
      vim.fn.writefile({'return {{trigger="prx",body="updated(${1:new})$0"}}'}, vim.env.PROJECT_SNIPPETS_FILE)
      assert(vim.secure.trust({path=vim.env.PROJECT_SNIPPETS_FILE,action='allow'}))
      assert(require('snippet_tools').reload())
    end, {buffer=true})
    _G.project_snippet_outside = function()
      require('snippet_tools').stop()
      vim.cmd('enew!')
      api.nvim_buf_set_name(0, vim.env.NVIM_TEST_TMP .. '/outside.lua')
      vim.bo.filetype = 'lua'
    end
    mark('typing')
  elseif stage == 'typing' and package.loaded.completion_tools then
    local completion = require('completion_tools')
    local item = completion.get_selected_item()
    if completion._can('accept') and item and item.label == 'prx' then mark('accept') end
  elseif stage == 'accept' and mode == 's' and line == 'project(value)' then
    mark('edit')
  elseif stage == 'edit' and mode == 'i' and line == 'project(XY)' then
    assert(require('snippet_tools').active())
    mark('finish')
  elseif stage == 'finish' and line == 'project(XY)!' then
    assert(not require('snippet_tools').active())
    mark('outside')
  elseif stage == 'outside' and api.nvim_buf_get_name(0) == vim.env.NVIM_TEST_TMP .. '/outside.lua' then
    local global = false
    for _, item in ipairs(require('snippet_tools').available()) do
      assert(item.trigger ~= 'prx', 'Project snippets escaped the directory scope')
      global = true
    end
    assert(global and #config_test_errors == 0, table.concat(config_test_errors, string.char(10)))
    vim.fn.writefile({'PASS'}, vim.env.PROJECT_SNIPPETS_RESULT)
    vim.cmd('qa!')
  end
end
local timer = vim.uv.new_timer()
timer:start(20, 20, vim.schedule_wrap(function()
  local ok, err = xpcall(check, debug.traceback)
  if not ok then
    timer:stop()
    vim.fn.writefile({err}, vim.env.PROJECT_SNIPPETS_RESULT)
    vim.cmd('cquit 1')
  end
end))
""")
    result, stage_file = temp / "result", temp / "stage"
    env = dict(
        os.environ,
        TERM="xterm-256color",
        NVIM_CONFIG_ROOT=str(ROOT),
        NVIM_TEST_TMP=str(temp),
        NVIM_TEST_SCENARIO="lua",
        NVIM_SMOKE_TEST="1",
        NVIM_TEST_ENABLE_THIRD_PARTY="0",
        XDG_CACHE_HOME=str(temp / "cache"),
        XDG_STATE_HOME=str(temp / "state"),
        NVIM_LOG_FILE=str(temp / "nvim.log"),
        NVIM_PLUGIN_LOCKFILE=str(lockfile),
        PROJECT_SNIPPETS_ROOT=str(project),
        PROJECT_SNIPPETS_FILE=str(snippets),
        PROJECT_SNIPPETS_MANIFEST=str(manifest),
        PROJECT_SNIPPETS_PROBE=str(probe),
        PROJECT_SNIPPETS_RESULT=str(result),
        PROJECT_SNIPPETS_STAGE=str(stage_file),
    )
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 32, 120, 0, 0))
    process = spawn(
        [
            "nvim",
            "-n",
            "-i",
            "NONE",
            "--cmd",
            "lua dofile(vim.env.NVIM_CONFIG_ROOT .. '/tests/support/setup.lua'); "
            "vim.fn.mkdir(vim.fn.stdpath('state'),'p'); "
            "assert(vim.secure.trust({path=vim.env.PROJECT_SNIPPETS_MANIFEST,action='allow'})); "
            "assert(vim.secure.trust({path=vim.env.PROJECT_SNIPPETS_FILE,action='allow'})); "
            "dofile(vim.env.PROJECT_SNIPPETS_PROBE)",
            "-u",
            str(ROOT / "init.lua"),
            str(sample),
        ],
        cwd=project / "nested",
        env=env,
        stdin=slave,
        stdout=slave,
        stderr=slave,
    )
    os.close(slave)
    actions = {
        "typing": b"iprx",
        "accept": b"\t",
        "edit": b"X\x1b[19~Y",
        "finish": b"\x1bl!",
        "outside": b"\x1b:lua project_snippet_outside()\r",
    }
    handled, output = set(), bytearray()
    try:
        deadline = time.monotonic() + 20
        while process.poll() is None and time.monotonic() < deadline:
            if select.select([master], [], [], 0.02)[0]:
                try:
                    output.extend(os.read(master, 65536))
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    break
            stage = stage_file.read_text().strip() if stage_file.exists() else ""
            if stage in actions and stage not in handled:
                os.write(master, actions[stage])
                handled.add(stage)
        message = (
            result.read_text() if result.exists() else "Timed out: " + repr(handled)
        )
        assert process.poll() == 0 and message.startswith("PASS"), (
            message + "\n" + output.decode(errors="replace")[-4000:]
        )
        print(
            "PASS configured project snippet PTY: lazy setup, relative root, completion, active reload and outside-buffer isolation"
        )
    finally:
        if process.poll() is None:
            stop(process)
            process.wait()
        os.close(master)
