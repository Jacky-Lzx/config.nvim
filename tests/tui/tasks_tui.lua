-- Invoke Lua APIs through the PTY; prompts and local UI interactions use real input.
local function pause(ms)
  coroutine.yield(ms)
end
local actions = {
  prompt = 'require("features.tasks").prompt()',
  manual_output = 'require("features.tasks").output()',
  quickfix = 'require("features.tasks").quickfix()',
  rerun = 'require("features.tasks").rerun()',
  list = 'require("task_tools").toggle()',
  select_task = 'require("task_tools").select()',
  run_args = 'require("features.tasks").run_file()',
  finished_output = 'assert(require("task_tools.integrations.notification_tools").open_last_output())',
}
if vim.env.NVIM_TEST_DISABLE_BINDINGS == "1" then
  for _, name in ipairs({ "terminal", "terminal_hide", "terminal_reopen", "terminal_hide_again" }) do
    actions[name] = 'require("task_tools").terminal()'
  end
end
local stage_file = vim.env.NVIM_TEST_TMP .. "/tasks-stage"
local function await(name, predicate)
  local lines = { name }
  if actions[name] then
    local leave_terminal = vim.api.nvim_get_mode().mode == "t" and "\28\14" or ""
    lines[2] = vim.json.encode(leave_terminal .. ":lua " .. actions[name] .. "\r")
  end
  vim.fn.writefile(lines, stage_file)
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
  local plugins = require("config.plugins").nodes()
  assert(
    plugins["task-tools.nvim"] and require("config.plugins").initialized("task-tools.nvim"),
    "task command registration is missing"
  )
  assert(#require("task_tools").list() == 0, "Registration started a task")
  assert(not plugins["overseer.nvim"] and not plugins["compile.nvim"])
  local root = vim.uv.fs_realpath(vim.env.NVIM_TEST_TMP) .. "/tasks-tui"
  vim.fn.mkdir(root .. "/src", "p")
  vim.fn.writefile({ "int main(void) {", "  return missing;", "}" }, root .. "/src/failure.c")
  vim.cmd("cd " .. vim.fn.fnameescape(root))
  await("prompt", function()
    return vim.fn.getcmdtype() == "@"
  end)
  assert(require("config.plugins").initialized("task-tools.nvim"))
  local tasks = require("task_tools")
  local terminals = require("task_tools.terminal")
  assert(require("task_tools.config").values.forward_osc133, "Personal OSC forwarding must be enabled")
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
  local source_win = vim.api.nvim_get_current_win()
  await("terminal", function()
    return #terminals.list() == 1 and #tasks.list() == 1 and vim.api.nvim_get_mode().mode == "t"
  end)
  local shell = terminals.list()[1]
  local win = vim.fn.win_findbuf(shell.buf)[1]
  assert(vim.api.nvim_win_get_config(win).relative == "editor", "default shell is floating")
  assert(not package.loaded["snacks.terminal"], "Snacks terminal should remain unloaded")
  await("terminal_input", function()
    return table.concat(vim.api.nvim_buf_get_lines(shell.buf, 0, -1, false), "\n"):find("TASKS_PTY_OK", 1, true) ~= nil
      and screen():find("TASKS_PTY_OK", 1, true) ~= nil
  end)
  await("terminal_hide", function()
    return #vim.fn.win_findbuf(shell.buf) == 0 and vim.api.nvim_get_mode().mode:sub(1, 1) == "n"
  end)
  assert(vim.api.nvim_get_current_win() == source_win, "Terminal toggle must restore the source window")
  await("terminal_reopen", function()
    return #vim.fn.win_findbuf(shell.buf) > 0 and vim.api.nvim_get_mode().mode == "t"
  end)
  assert(terminals.get(shell.buf).job == shell.job, "Terminal action must reuse the original PTY")
  await("terminal_hide_again", function()
    return #vim.fn.win_findbuf(shell.buf) == 0 and vim.api.nvim_get_mode().mode:sub(1, 1) == "n"
  end)
  await("rerun", function()
    return #tasks.list() == 2 and tasks.list()[1].status == "success"
  end)
  local repeated = tasks.list()[1]
  assert(
    repeated.mode == "pipe" and repeated.cwd == root and repeated.cmd == tasks.get(manual).cmd,
    "manual repeat must ignore latest terminal"
  )
  await("list", function()
    return vim.bo.filetype == "tasktools"
  end)
  assert(not screen():find("Terminal", 1, true) and screen():find("success", 1, true), "task list excludes shell")
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
    return #tasks.list() == 3 and tasks.list()[1].status == "success"
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
    return #tasks.list() == 4 and tasks.list()[1].status == "success"
  end)
  assert(
    table.concat(tasks.output(tasks.list()[1].id), "\n"):find("ARGS:[]", 1, true),
    "TaskRun uses the configured live interpreter"
  )
  local notices = require("notification-tools")
  local function notice(id)
    for _, row in ipairs(notices.tasks()) do
      if row.id == "task-tools:" .. id then
        return row
      end
    end
  end
  assert(not vim.iter(notices.tasks()):any(function(row)
    return row.title == "Terminal"
  end), "Personal shell must not create a task progress row")
  local gate = root .. "/notification-gate"
  local current_win, cursor = vim.api.nvim_get_current_win(), vim.api.nvim_win_get_cursor(0)
  local progress = assert(tasks.run({
    name = "Notification gate",
    cmd = {
      python,
      "-u",
      "-c",
      "import pathlib,sys,time; print('ready',flush=True); gate=pathlib.Path(sys.argv[1]); deadline=time.monotonic()+10\nwhile not gate.exists() and time.monotonic()<deadline: time.sleep(.01)\nprint('TASK_PROGRESS_FINISHED',flush=True)",
      gate,
    },
  }, { open = false }))
  await("progress_visible", function()
    return notice(progress) and not notice(progress).done and screen():find("Notification gate", 1, true)
  end)
  assert(vim.api.nvim_get_current_win() == current_win and vim.deep_equal(vim.api.nvim_win_get_cursor(0), cursor))
  local failure = assert(
    tasks.run(
      { name = "Notification failure", cmd = { "sh", "-c", "printf 'TASK_FAILURE_SUMMARY\\n'; exit 9" } },
      { open = false }
    )
  )
  await("progress_failure", function()
    return notice(failure) and notice(failure).status == "error"
  end)
  assert(notice(failure).message:find("Exit 9: TASK_FAILURE_SUMMARY", 1, true))
  assert(vim.iter(notices.history({ source = "task-tools" })):any(function(row)
    return row.message:find("TASK_FAILURE_SUMMARY", 1, true)
  end))
  vim.fn.writefile({}, gate)
  await("progress_success", function()
    return notice(progress) and notice(progress).status == "success"
  end)
  await("finished_output", function()
    return vim.bo.filetype == "tasktoolsoutput" and screen():find("TASK_PROGRESS_FINISHED", 1, true)
  end)
  terminals.stop(shell.buf)
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end
vim.api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    local worker = coroutine.create(check)
    local function advance()
      local ok, delay = coroutine.resume(worker)
      if not ok or coroutine.status(worker) == "dead" then
        local message = ok
            and "tasks TUI: lazy loading, manual commands, quickfix jumps, terminal PTY, Python arguments, task discovery and rendered progress/output handoff passed"
          or debug.traceback(worker, tostring(delay))
        vim.fn.writefile(vim.split(message, "\n", { plain = true }), vim.env.NVIM_STARTUP_RESULT)
        vim.cmd(ok and "qa!" or "cquit 1")
      else
        vim.defer_fn(advance, delay)
      end
    end
    vim.defer_fn(advance, 100)
  end,
})
