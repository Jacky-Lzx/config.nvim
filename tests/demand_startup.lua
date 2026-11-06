local function check()
  local plugins = require("config.plugins")
  local manager = plugins.manager
  local function cold(id, module)
    assert(manager.states[id].phase == "registered", id .. " mounted before first use")
    assert(not package.loaded[module], module .. " loaded before first use")
  end
  if vim.env.NVIM_DEMAND_COMMANDS == "1" then
    cold("workspace-tools.nvim", "workspace_tools")
    assert(not package.loaded["workspace_tools.environments.python"])
    vim.cmd.lcd(assert(vim.env.NVIM_TEST_TMP))
    vim.cmd("VenvSelect!")
    assert(plugins.initialized("workspace-tools.python"))
    assert(manager.states["workspace-tools.python"].count == 1)
    assert(not package.loaded.workspace_tools, "Environment selection initialized session management")
    assert(package.loaded["workspace_tools.environments.python"])
    assert(vim.fn.exists(":WorkspacePython") == 2)
    assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
    io.stdout:write("Demand command: VenvSelect before FileType initializes only the Python environment provider\n")
    return
  end
  cold("tex-tools.nvim", "tex-tools")
  cold("nvim-lspconfig", "lspconfig")
  assert(not package.loaded["workspace_tools.environments.python"])
  assert(not package.loaded["languages.python.interpreter"])
  assert(not package.loaded["completion_tools"] and not package.loaded["snippet_tools"])
  assert(vim.fn.exists(":VenvSelect") == 2)

  local temp = assert(vim.env.NVIM_TEST_TMP)
  vim.fn.writefile({ "print('first')" }, temp .. "/demand.py")
  vim.cmd.edit(temp .. "/demand.py")
  assert(plugins.initialized("workspace-tools.python"))
  assert(package.loaded["workspace_tools.environments.python"])
  assert(manager.states["nvim-lspconfig"].phase == "mounted")
  assert(vim.lsp.is_enabled("basedpyright"))
  assert(not package.loaded["tex-tools"])
  vim.cmd.enew()
  vim.bo.filetype = "python"
  assert(manager.states["workspace-tools.python"].count == 1)

  vim.fn.writefile(
    { "\\documentclass{article}", "\\begin{document}", "body", "\\end{document}" },
    temp .. "/demand.tex"
  )
  vim.cmd.edit(temp .. "/demand.tex")
  assert(vim.bo.filetype == "tex" and vim.g.tex_flavor == "latex")
  assert(vim.b.tex_tools_generation and plugins.initialized("tex-tools.nvim"))
  assert(vim.fn.maparg("<Space>lv", "n") == "<Cmd>TexToolsForwardSearch<CR>")
  assert(not package.loaded["tex-tools.formula.render"], "TeX attachment loaded the formula compiler")
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.api.nvim_feedkeys(vim.keycode("A burst_input_123<Esc>"), "xt", false)
  assert(vim.api.nvim_get_current_line() == "body burst_input_123")
  vim.cmd.enew({ bang = true })
  vim.bo.filetype = "tex"
  assert(vim.b.tex_tools_generation and manager.states["tex-tools.nvim"].count == 1)
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
  io.stdout:write(
    "Demand startup: cold resources, native Python LSP, first/repeated TeX buffers and burst input passed\n"
  )
end

local function run()
  local ok, err = xpcall(check, debug.traceback)
  if vim.env.NVIM_STARTUP_RESULT then
    vim.fn.writefile({ ok and "passed" or tostring(err) }, vim.env.NVIM_STARTUP_RESULT)
  end
  if not ok then
    io.stderr:write(err .. "\n")
  end
  vim.cmd(ok and "qa!" or "cquit 1")
end
if vim.g.config_ready then
  vim.schedule(run)
else
  vim.api.nvim_create_autocmd("User", {
    pattern = "ConfigReady",
    once = true,
    callback = function()
      vim.schedule(run)
    end,
  })
end
