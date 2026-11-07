-- Keep smoke runs offline and avoid starting external servers. The startup pass still
-- resolves native server configs and verifies which servers the configuration enables.
dofile(assert(vim.env.NVIM_CONFIG_ROOT) .. "/tests/support/full_plugins.lua")
vim.g.loaded_wakatime = true
-- Startup/input tests must not overwrite the host's real clipboard.
vim.g.clipboard = {
  name = "smoke-test",
  copy = { ["+"] = function() end, ["*"] = function() end },
  paste = {
    ["+"] = function()
      return { {}, "v" }
    end,
    ["*"] = function()
      return { {}, "v" }
    end,
  },
  cache_enabled = 0,
}
_G.config_test_errors = {}
local notify = vim.notify
vim.notify = function(message, level, opts)
  if level == vim.log.levels.ERROR then
    table.insert(_G.config_test_errors, tostring(message))
  end
  return notify(message, level, opts)
end
_G.config_test_real_lsp_start = vim.lsp.start
_G.config_test_lsp_starts = {}
vim.lsp.start = function(config)
  table.insert(_G.config_test_lsp_starts, vim.deepcopy(config))
  return nil
end

_G.config_test_lsp_enabled = {}
local enable = vim.lsp.enable
vim.lsp.enable = function(names, enabled)
  for _, name in ipairs(type(names) == "table" and names or { names }) do
    _G.config_test_lsp_enabled[name] = vim.deepcopy(vim.lsp.config[name].capabilities)
  end
  return enable(names, enabled)
end

local scenario = vim.env.NVIM_TEST_SCENARIO
local scenarios = dofile(vim.env.NVIM_CONFIG_ROOT .. "/tests/support/scenarios.lua")
assert(not scenario or scenario == "default" or scenarios[scenario], "Unknown test scenario: " .. tostring(scenario))
local selection = scenarios[scenario]
vim.opt.runtimepath:prepend(vim.env.NVIM_CONFIG_ROOT)
if vim.env.NVIM_TEST_REMAP_ACTIONS == "1" then
  dofile(vim.env.NVIM_CONFIG_ROOT .. "/tests/support/remapped_actions.lua")
end
require("config.context").initialize(selection)

-- Permission-warning floats must not obscure rendered-screen assertions.
dofile(vim.env.NVIM_CONFIG_ROOT .. "/tests/support/toolchain_sessions.lua")
