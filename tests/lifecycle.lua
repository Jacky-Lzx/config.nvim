local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
dofile(root .. "/tests/setup.lua")
vim.o.loadplugins = true
dofile(root .. "/init.lua")
dofile(root .. "/tests/native_plugins.lua")
assert(
  vim.wait(3000, function()
    return vim.g.config_ready == true
  end),
  "ConfigReady was not reached"
)

local plugins = require("config.plugins")
local actions = dofile(root .. "/tests/actions.lua")
local count = 0
for _, entry in ipairs({
  { "editing-tools.nvim", "editing_tools" },
  { "file-tools.nvim", "file_tools" },
  { "motion-tools.nvim", "motion_tools" },
  { "selection-tools.nvim", "selection_tools" },
  { "ui-tools.nvim", "ui_tools" },
  { "workspace-tools.nvim", "workspace_tools" },
  { "lsp-tools.nvim", "lsp-tools" },
  { "task-tools.nvim", "task_tools" },
  { "format-tools.nvim", "format_tools" },
  { "lint-tools.nvim", "lint_tools" },
}) do
  local id, module = entry[1], entry[2]
  if plugins.manager:has(id) then
    plugins.manager:activate(id)
    local api = require(module)
    local options = plugins.options(id)
    local commands = vim.api.nvim_get_commands({})
    local handlers = vim.api.nvim_get_autocmds({})
    assert(not pcall(api.setup, false), id .. " accepted invalid options")
    assert(vim.deep_equal(commands, vim.api.nvim_get_commands({})), id .. " replaced commands on invalid setup")
    assert(vim.deep_equal(handlers, vim.api.nvim_get_autocmds({})), id .. " replaced handlers on invalid setup")
    assert(api.dispose() ~= false, id .. " could not dispose an idle instance")
    assert(api.dispose() ~= false, id .. " could not dispose twice")
    assert(actions.audit() > 0, id .. " removed personal bindings")
    api.setup(options)
    assert(actions.audit() > 0, id .. " replaced personal bindings on setup")
    count = count + 1
  end
end
assert(count >= 8, "Configured lifecycle coverage unexpectedly shrank")
assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
io.stdout:write(
  ("Configured lifecycle: %d owners preserve personal bindings across invalid setup, disposal and restart\n"):format(
    count
  )
)
