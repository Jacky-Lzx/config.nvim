local api = vim.api
local temp = assert(vim.env.NVIM_TEST_TMP)
local result = assert(vim.env.NVIM_STARTUP_RESULT)
local stage, source_buf, source_win = "initial", nil, nil
local optional_ready, submitted = false, nil
local timer = vim.uv.new_timer()
local function mark(name)
  stage = name
  vim.fn.writefile({ name }, temp .. "/toolchain-stage")
end
local function check()
  if stage == "initial" then
    if not vim.g.config_ready then
      return
    end
    vim.cmd("enew!")
    source_buf, source_win = api.nvim_get_current_buf(), api.nvim_get_current_win()
    api.nvim_buf_set_lines(source_buf, 0, -1, false, { "local value = 1", "-- unsaved source" })
    vim.bo[source_buf].filetype = "lua"
    assert(package.loaded.toolchain and #require("toolchain").status() == 0)
    vim.cmd("Mason")
    assert(vim.bo.filetype == "toolchain" and #require("toolchain").status() == 0)
    vim.cmd("ToolchainPlan")
    assert(not package.loaded.mason and #require("toolchain").status() == 0)
    assert(vim.bo.filetype == "toolchain")
    mark("plan")
  elseif stage == "plan" and api.nvim_get_current_win() == source_win then
    local tc = require("toolchain")
    local install = tc.install
    tc.install = function(requirements)
      submitted = requirements
      -- Exercise the real queue with local checks only; never download the full profile.
      return install({
        { provider = "system", name = "sh" },
        {
          provider = "system",
          name = "toolchain-config-optional-123",
          optional = true,
          resolve = function()
            return optional_ready and vim.fn.exepath("sh") or nil
          end,
        },
      })
    end
    mark("install")
  elseif stage == "install" and submitted then
    local tc = require("toolchain")
    local tasks = tc.status()
    if #tasks ~= 2 or tasks[2].state ~= "unavailable" then
      return
    end
    assert(vim.deep_equal(submitted, require("integrations.toolchain").requirements()))
    assert(tasks[1].state == "skipped")
    vim.cmd("Toolchain")
    api.nvim_win_set_cursor(0, { 5, 0 })
    mark("tasks")
  elseif stage == "tasks" then
    local lines = api.nvim_buf_get_lines(0, 0, -1, false)
    if lines[4] == "system:toolchain-config-optional-123  [unavailable]" then
      optional_ready = true
      mark("retry")
    end
  elseif stage == "retry" then
    local task = require("toolchain").status()[2]
    local lines = api.nvim_buf_get_lines(0, 0, -1, false)
    if task.attempt == 2 and task.state == "skipped" and lines[4]:find("[skipped]", 1, true) then
      mark("close")
    end
  elseif stage == "close" and api.nvim_get_current_win() == source_win then
    assert(api.nvim_get_current_buf() == source_buf and vim.bo[source_buf].modified)
    assert(vim.deep_equal(api.nvim_buf_get_lines(source_buf, 0, -1, false), { "local value = 1", "-- unsaved source" }))
    assert(vim.treesitter.highlighter.active[source_buf], "Existing Tree-sitter highlighting must remain active")
    assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
    timer:stop()
    timer:close()
    vim.fn.writefile({
      "PASS configured toolchain loading, Plan, ConfigToolsInstall, optional retry, source/highlighting preserved",
    }, result)
    vim.cmd("qa!")
  end
end
timer:start(
  20,
  20,
  vim.schedule_wrap(function()
    local ok, err = xpcall(check, debug.traceback)
    if not ok then
      timer:stop()
      timer:close()
      vim.fn.writefile(vim.split(err, "\n", { plain = true }), result)
      vim.cmd("cquit 1")
    end
  end)
)
