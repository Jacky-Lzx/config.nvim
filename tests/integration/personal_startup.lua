-- Actual personal defaults: assertions follow declarations, not a copied inventory.
local function check()
  local expected = require("config.selection_schema").normalize(require("config.selection"))
  local context = require("config.context").current()
  assert(vim.deep_equal(context.selection, expected), "Startup did not use personal selection")
  local plugins = require("config.plugins")
  for id, node in pairs(plugins.nodes()) do
    assert(vim.fn.isdirectory(node.dir) == 1, "Configured plugin unavailable: " .. id)
    if node.start then
      assert(plugins.initialized(id), "Configured startup action failed: " .. id)
    end
  end
  assert(vim.fn.exists(":ConfigInfo") == 2)
  local info = require("config").info()
  assert(vim.deep_equal(info.languages.servers, context.languages.servers))
  local actions = dofile(vim.env.NVIM_CONFIG_ROOT .. "/tests/support/actions.lua")
  for _, ft in ipairs({ "lua", "python", "markdown", "tex", "typst" }) do
    vim.cmd("enew!")
    vim.bo.filetype = ft
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unchanged source" })
    actions.audit()
    assert(vim.api.nvim_get_current_line() == "unchanged source", "Filetype activation changed source: " .. ft)
  end
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
  io.stdout:write(
    "Personal defaults: selected startup owners, language projection, effective mappings and source preservation passed\n"
  )
end
local function run()
  local ok, err = xpcall(check, debug.traceback)
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
