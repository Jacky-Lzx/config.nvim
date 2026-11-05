local root = assert(vim.env.NVIM_CONFIG_ROOT)
local directory = assert(vim.env.NVIM_TEST_TMP) .. "/workspace-tui"
vim.fn.mkdir(directory, "p")
directory = vim.uv.fs_realpath(directory)
local a, b = directory .. "/alpha", directory .. "/beta"
vim.fn.mkdir(a, "p")
vim.fn.mkdir(b, "p")
vim.fn.writefile({ "alpha" }, a .. "/one.txt")
vim.fn.writefile({ "alpha other" }, a .. "/two.txt")
vim.fn.writefile({ "beta" }, b .. "/file.txt")
local phase, picker, alpha, beta, ticks, finished = "startup", nil, nil, nil, 0, false
local function mark(stage)
  vim.fn.writefile({ stage }, directory .. "/stage")
end
local function finish(ok, message)
  if finished then
    return
  end
  finished = true
  vim.fn.writefile(vim.split(message, "\n", { plain = true }), directory .. "/result")
  vim.cmd(ok and "qa!" or "cquit 1")
end
local timer = vim.uv.new_timer()
timer:start(
  30,
  30,
  vim.schedule_wrap(function()
    if finished then
      timer:stop()
      timer:close()
      return
    end
    local ok, err = xpcall(function()
      ticks = ticks + 1
      assert(ticks < 700, "timeout at " .. phase)
      local workspace = package.loaded.workspace_tools
      if phase == "startup" then
        local plugins = require("config.plugins").nodes()
        if not require("config.plugins").initialized("workspace-tools.nvim") then
          return
        end
        assert(not plugins["auto-session"] and vim.fn.exists(":AutoSession") == 0)
        assert(workspace.status().initialized)
        local options = require("workspace_tools.config").options
        assert(not options.auto_save and not options.auto_restore)
        local selection = require("selection_tools")
        local select = selection.select
        selection.select = function(...)
          picker = select(...)
          return picker
        end
        vim.api.nvim_set_current_dir(a)
        vim.cmd.edit(a .. "/one.txt")
        vim.cmd.vsplit(a .. "/two.txt")
        phase = "save_alpha"
        mark("save_alpha")
      elseif phase == "save_alpha" and #workspace.list() == 1 then
        alpha = workspace.list()[1]
        assert(alpha.cwd == a and #alpha.files == 2)
        vim.cmd("only")
        vim.api.nvim_set_current_dir(b)
        vim.cmd.edit(b .. "/file.txt")
        phase = "save_beta"
        mark("save_beta")
      elseif phase == "save_beta" and #workspace.list() == 2 then
        beta = workspace.list()[1]
        assert(beta.name == "BetaTargetWorkspace")
        vim.api.nvim_set_current_dir(a)
        vim.cmd.edit(a .. "/one.txt")
        phase = "restore_alpha"
        mark("restore_alpha")
      elseif phase == "restore_alpha" and workspace.status().active.id == alpha.id then
        assert(#vim.api.nvim_tabpage_list_wins(0) == 2, "restore shortcut lost the saved splits")
        phase = "search"
        mark("search")
      elseif phase == "search" and picker and not picker.closed and vim.api.nvim_get_mode().mode == "i" then
        assert(picker.opts.prompt == "Workspaces")
        phase = "query"
        mark("query")
      elseif phase == "query" and picker.query == "BetaTargetWorkspace" then
        if #picker.matches ~= 1 then
          return
        end
        assert(workspace.status().active.id == alpha.id, "typing changed workspace")
        phase = "choose"
        mark("choose")
      elseif phase == "choose" and picker.closed and workspace.status().active.id == beta.id then
        assert(vim.api.nvim_buf_get_name(0) == b .. "/file.txt")
        assert(vim.api.nvim_get_mode().mode == "n")
        phase = "delete_prompt"
        mark("delete_prompt")
      elseif phase == "delete_prompt" and picker and not picker.closed and vim.api.nvim_get_mode().mode == "i" then
        assert(picker.opts.prompt:find("Delete workspace", 1, true))
        phase = "delete_filter"
        mark("delete_filter")
      elseif phase == "delete_filter" and picker.query == "Delete" and #picker.matches == 1 then
        phase = "delete_confirm"
        mark("delete_confirm")
      elseif phase == "delete_confirm" and picker.closed and #workspace.list() == 1 then
        assert(workspace.status().stopped, "deletion did not pause exit save")
        vim.api.nvim_set_current_dir(a)
        vim.cmd.edit(a .. "/one.txt")
        require("ui_tools").dashboard()
        assert(require("ui_tools.dashboard").state(), "dashboard did not open")
        phase = "dashboard"
        mark("dashboard")
      elseif phase == "dashboard" and workspace.status().active and workspace.status().active.id == alpha.id then
        assert(vim.bo.filetype ~= "ui_tools_dashboard", "dashboard restore left dashboard focused")
        assert(#vim.api.nvim_tabpage_list_wins(0) == 2)
        assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
        finish(
          true,
          "PASS configured TUI: ConfigReady, save/restore/search/delete mappings, real selection picker, confirmation and dashboard restore"
        )
      end
    end, debug.traceback)
    if not ok then
      finish(false, err)
    end
  end)
)
