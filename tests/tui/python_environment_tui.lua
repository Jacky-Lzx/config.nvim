local api = vim.api
local folder = assert(vim.uv.fs_realpath(vim.env.NVIM_TEST_TMP)) .. "/python-environments"
local environments, source, first, selected, second_python, project_a, project_b, target
local finished = false
local function finish(err)
  if finished then
    return
  end
  finished = true
  for _, client in ipairs(vim.lsp.get_clients()) do
    client:stop(true)
  end
  vim.fn.writefile(err and vim.split(err, "\n", { plain = true }) or {
    "PASS configured Python PTY: real picker input/cancel, project isolation, persistent selection, actual BasedPyright import resolution, task/DAP environments and reset",
  }, vim.env.NVIM_STARTUP_RESULT)
  vim.cmd(err and "cquit 1" or "qa!")
end
local function safe(fn)
  local ok, err = xpcall(fn, debug.traceback)
  if not ok then
    finish(err)
  end
end
local function await(predicate, done)
  local deadline = vim.uv.hrtime() + 15e9
  local function poll()
    if finished then
      return
    end
    safe(function()
      if predicate() then
        done()
      elseif vim.uv.hrtime() > deadline then
        error("Timed out waiting for Python migration stage")
      else
        vim.defer_fn(poll, 25)
      end
    end)
  end
  vim.defer_fn(poll, 25)
end
local function stage(name)
  vim.fn.writefile({ name }, vim.env.NVIM_TEST_TMP .. "/python-stage")
end
local function clients(buf)
  return vim.lsp.get_clients({ name = "basedpyright", bufnr = buf })
end
local function after_cancel()
  assert(environments.current({ root = project_b }) == second_python)
  api.nvim_set_current_buf(source)
  local settings = { directory = folder .. "/store", search_paths = { folder .. "/envs" } }
  environments.setup(settings)
  assert(environments.current() == selected, "project selection must survive cache reload")
  vim.cmd("VenvSelect!")
  assert(environments.current() == project_a .. "/.venv/bin/python")
  assert(first.settings.python.pythonPath == project_a .. "/.venv/bin/python")
  assert(not package.loaded["venv-selector"])
  assert(not package.loaded.workspace_tools, "Python environment module must not initialize session management")
  finish()
end
local function after_selection()
  assert(api.nvim_get_current_buf() == source and vim.fn.mode() == "n")
  assert(first.settings.python.pythonPath == selected)
  local snapshot = require("config.inspect").snapshot().integrations.python
  assert(snapshot.root == project_a and snapshot.python == selected and snapshot.source == "selection")
  local env = require("languages.python.interpreter").environment()
  local actual = vim
    .system(
      { selected, "-c", 'import sys,os; print(sys.prefix); print(os.environ.get("VIRTUAL_ENV"))' },
      { text = true, env = env }
    )
    :wait()
  assert(
    actual.code == 0 and actual.stdout == folder .. "/envs/chosen\n" .. folder .. "/envs/chosen\n",
    vim.inspect(actual)
  )
  local definitions = require("task_tools").discover()
  local task
  for _, item in ipairs(definitions) do
    if item.name == "Python: run file" then
      task = item
    end
  end
  assert(task and task.cmd[1] == selected and task.env.VIRTUAL_ENV == folder .. "/envs/chosen")
  local dap = require("dap_tools").backend().configurations.python[1]
  assert(dap.pythonPath() == selected and dap.env().VIRTUAL_ENV == folder .. "/envs/chosen")
  assert(
    vim.wait(12000, function()
      local response = first:request_sync(
        "textDocument/definition",
        { textDocument = { uri = vim.uri_from_bufnr(source) }, position = { line = 1, character = 5 } },
        1500,
        source
      )
      for _, item in ipairs(response and response.result or {}) do
        if (item.uri or item.targetUri) == vim.uri_from_fname(target) then
          return true
        end
      end
      return false
    end, 50),
    "BasedPyright did not resolve the module installed only in the selected venv"
  )
  vim.cmd.edit(project_b .. "/main.py")
  local other = api.nvim_get_current_buf()
  assert(require("languages.python.interpreter").current() == second_python)
  await(function()
    return clients(other)[1] and clients(other)[1].initialized
  end, function()
    assert(first.settings.python.pythonPath == selected, "opening project B must not change project A")
    stage("open_other")
    await(function()
      return vim.bo.filetype == "selection_tools_input"
    end, function()
      stage("cancel")
      await(function()
        return api.nvim_get_current_buf() == other and vim.fn.mode() == "n"
      end, after_cancel)
    end)
  end)
end
local function start()
  local plugins = require("config.plugins").nodes()
  assert(not plugins["venv-selector.nvim"])
  assert(
    not require("config.plugins").initialized("workspace-tools.nvim"),
    "environment-only workspace runtime should stay cold"
  )
  project_a, project_b = folder .. "/a", folder .. "/b"
  local base = vim.fn.exepath("python3")
  for _, path in ipairs({ project_a .. "/.venv", project_b .. "/.venv", folder .. "/envs/chosen" }) do
    local process = vim.system({ base, "-m", "venv", "--without-pip", path }, { text = true }):wait()
    assert(process.code == 0, process.stderr)
  end
  for _, path in ipairs({ project_a, project_b }) do
    vim.fn.writefile({ "[project]", 'name="migration-fixture"', 'version="0.0.0"' }, path .. "/pyproject.toml")
    vim.fn.writefile({ "from migration_fixture import selected_only", "selected_only()" }, path .. "/main.py")
  end
  selected, second_python = folder .. "/envs/chosen/bin/python", project_b .. "/.venv/bin/python"
  local info = vim
    .system({ selected, "-c", 'import sysconfig; print(sysconfig.get_path("purelib"))' }, { text = true })
    :wait()
  assert(info.code == 0, info.stderr)
  target = vim.trim(info.stdout) .. "/migration_fixture.py"
  vim.fn.writefile({ "def selected_only() -> str:", '    return "selected"' }, target)
  vim.lsp.start = _G.config_test_real_lsp_start
  vim.cmd.edit(project_a .. "/main.py")
  source = api.nvim_get_current_buf()
  environments = require("python_tools")
  environments.setup({ directory = folder .. "/store", search_paths = { folder .. "/envs" } })
  assert(require("languages.python.interpreter").current() == project_a .. "/.venv/bin/python")
  await(function()
    first = clients(source)[1]
    return first and first.initialized
  end, function()
    stage("open")
    await(function()
      return vim.bo.filetype == "selection_tools_input"
    end, function()
      stage("choose")
      await(function()
        return environments.current({ root = project_a }) == selected and api.nvim_get_current_buf() == source
      end, after_selection)
    end)
  end)
end
local function ready()
  if vim.g.config_ready then
    safe(start)
  else
    vim.defer_fn(ready, 25)
  end
end
vim.defer_fn(ready, 25)
