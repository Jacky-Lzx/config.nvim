-- Physical key input is supplied by tests/tui.py, with the actual configuration.
local function pause(ms)
  coroutine.yield(ms)
end
local stage_file = vim.env.NVIM_TEST_TMP .. "/tasks-stage"
local function await(name, predicate)
  vim.fn.writefile({ name }, stage_file)
  local start = vim.uv.hrtime()
  while not predicate() do
    assert(
      (vim.uv.hrtime() - start) / 1e9 < 8,
      "timeout: "
        .. name
        .. " mode="
        .. vim.api.nvim_get_mode().mode
        .. " cmdtype="
        .. vim.fn.getcmdtype()
        .. " line="
        .. vim.fn.getcmdline()
        .. " tasks="
        .. vim.inspect(package.loaded.task_tools and package.loaded.task_tools.list())
    )
    pause(30)
  end
end
local function screen()
  vim.cmd("redraw!")
  local lines = {}
  for row = 1, vim.o.lines do
    local line = ""
    for col = 1, vim.o.columns do
      line = line .. vim.fn.screenstring(row, col)
    end
    lines[#lines + 1] = line
  end
  return table.concat(lines, "\n")
end
local function check()
  local plugins = require("lazy.core.config").plugins
  assert(plugins["task-tools.nvim"] and not plugins["task-tools.nvim"]._.loaded, "tasks should stay lazy at startup")
  assert(not package.loaded.task_tools, "bars must not load task-tools")
  assert(not plugins["overseer.nvim"] and not plugins["compile.nvim"])
  local root = vim.uv.fs_realpath(vim.env.NVIM_TEST_TMP) .. "/tasks-tui"
  vim.fn.mkdir(root .. "/src", "p")
  vim.fn.writefile({ "int main(void) {", "  return missing;", "}" }, root .. "/src/failure.c")
  vim.cmd("cd " .. vim.fn.fnameescape(root))
  await("prompt", function()
    return vim.fn.getcmdtype() == "@"
  end)
  assert(plugins["task-tools.nvim"]._.loaded)
  local tasks = require("task_tools")
  assert(plugins["task-tools.nvim"].dir == require("utils.platform").dev_plugin_root() .. "/task-tools.nvim")
  await("command", function()
    return #tasks.list() == 1 and tasks.list()[1].status == "success"
  end)
  local manual = tasks.list()[1].id
  await("manual_output", function()
    return vim.bo.filetype == "tasktoolsoutput"
  end)
  assert(screen():find("src/failure.c:2:3", 1, true), "rendered build output")
  await("quickfix", function()
    return vim.bo.buftype == "quickfix"
  end)
  assert(vim.fn.getqflist({ context = 0 }).context.id == manual)
  await("jump", function()
    return vim.api.nvim_buf_get_name(0) == root .. "/src/failure.c"
  end)
  assert(vim.api.nvim_win_get_cursor(0)[1] == 2 and vim.api.nvim_win_get_cursor(0)[2] == 2)
  await("terminal", function()
    return #tasks.list() == 2 and vim.api.nvim_get_mode().mode == "t"
  end)
  local shell = tasks.list()[1]
  local win = vim.fn.win_findbuf(shell.buf)[1]
  assert(vim.api.nvim_win_get_config(win).relative == "editor", "default shell is floating")
  assert(not package.loaded["snacks.terminal"], "Snacks terminal should remain unloaded")
  await("terminal_input", function()
    return table.concat(tasks.output(shell.id), "\n"):find("TASKS_PTY_OK", 1, true) ~= nil
      and screen():find("TASKS_PTY_OK", 1, true) ~= nil
  end)
  await("terminal_hide", function()
    return #vim.fn.win_findbuf(shell.buf) == 0 and vim.api.nvim_get_mode().mode:sub(1, 1) == "n"
  end)
  await("terminal_reopen", function()
    return #vim.fn.win_findbuf(shell.buf) > 0 and vim.api.nvim_get_mode().mode == "t"
  end)
  assert(tasks.get(shell.id).job == shell.job, "Alt-i must reuse the original PTY")
  await("terminal_hide_again", function()
    return #vim.fn.win_findbuf(shell.buf) == 0 and vim.api.nvim_get_mode().mode:sub(1, 1) == "n"
  end)
  await("rerun", function()
    return #tasks.list() == 3 and tasks.list()[1].status == "success"
  end)
  local repeated = tasks.list()[1]
  assert(
    repeated.mode == "pipe" and repeated.cwd == root and repeated.cmd == tasks.get(manual).cmd,
    "manual repeat must ignore latest terminal"
  )
  await("list", function()
    return vim.bo.filetype == "tasktools"
  end)
  assert(screen():find("Terminal", 1, true) and screen():find("success", 1, true), "rendered task list")
  await("list_close", function()
    return vim.bo.filetype ~= "tasktools"
  end)
  local python = vim.fn.exepath("python3")
  assert(python ~= "")
  require("languages.python.interpreter").set_provider(function()
    return python
  end)
  vim.fn.writefile({ "import sys", "print('ARGS:' + repr(sys.argv[1:]))" }, root .. "/args file.py")
  vim.cmd.edit(vim.fn.fnameescape(root .. "/args file.py"))
  await("run_args", function()
    return vim.fn.getcmdtype() == "@"
  end)
  await("args", function()
    return #tasks.list() == 4 and tasks.list()[1].status == "success"
  end)
  pause(80)
  assert(
    table.concat(tasks.output(tasks.list()[1].id), "\n"):find("ARGS:['hello world', '']", 1, true),
    "real Python preserves quoted and empty arguments"
  )
  await("args_normal", function()
    return vim.api.nvim_get_mode().mode:sub(1, 1) == "n"
  end)
  local args_buf = tasks.list()[1].buf
  await("args_close", function()
    return #vim.fn.win_findbuf(args_buf) == 0
  end)
  await("select_task", function()
    return vim.bo.filetype == "selection_tools_input"
  end)
  await("task_choice", function()
    return #tasks.list() == 5 and tasks.list()[1].status == "success"
  end)
  assert(
    table.concat(tasks.output(tasks.list()[1].id), "\n"):find("ARGS:[]", 1, true),
    "TaskRun uses the configured live interpreter"
  )
  tasks.stop(shell.id)
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    local worker = coroutine.create(check)
    local function advance()
      local ok, delay = coroutine.resume(worker)
      if not ok or coroutine.status(worker) == "dead" then
        local message = ok
            and "tasks TUI: lazy loading, manual commands, quickfix jumps, Alt-i PTY, Python arguments and task discovery passed"
          or debug.traceback(worker, tostring(delay))
        vim.fn.writefile(vim.split(message, "\n", { plain = true }), vim.env.NVIM_LAZY_RESULT)
        vim.cmd(ok and "qa!" or "cquit 1")
      else
        vim.defer_fn(advance, delay)
      end
    end
    vim.defer_fn(advance, 100)
  end,
})
