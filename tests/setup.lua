-- Keep smoke runs offline and avoid starting external servers. The startup pass still
-- resolves native server configs and verifies which servers the configuration enables.
vim.g.loaded_wakatime = true
_G.config_test_errors = {}
local notify = vim.notify
vim.notify = function(message, level, opts)
  if level == vim.log.levels.ERROR then
    table.insert(_G.config_test_errors, tostring(message))
  end
  return notify(message, level, opts)
end
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
if scenario == "minimal" then
  package.loaded["config.selection"] = {
    profiles = {},
    features = {},
  }
elseif scenario == "python" then
  package.loaded["config.selection"] = {
    profiles = { "data" },
    features = { ai = false, debugging = true, tasks = false, sessions = false },
  }
end
