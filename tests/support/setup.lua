-- Keep smoke runs offline and avoid starting external servers. The startup pass still
-- resolves native server configs and verifies which servers the configuration enables.
dofile(assert(vim.env.NVIM_CONFIG_ROOT) .. "/tests/support/full_plugins.lua")
vim.g.loaded_wakatime = true
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if #vim.api.nvim_list_uis() == 0 then
      return
    end
    pcall(function()
      vim.cmd.redraw()
      local lines = {}
      for row = 1, vim.o.lines do
        local cells = {}
        for col = 1, vim.o.columns do
          cells[#cells + 1] = vim.fn.screenstring(row, col)
        end
        lines[#lines + 1] = table.concat(cells)
      end
      vim.fn.writefile(lines, (vim.env.NVIM_TEST_ARTIFACT_DIR or vim.env.NVIM_TEST_TMP) .. "/screen.txt")
    end)
  end,
})
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
-- Explicit -u starts with an isolated XDG_CONFIG_HOME still need this checkout's
-- native after/ hooks, just as a normal installed configuration would receive.
vim.opt.runtimepath:append(vim.env.NVIM_CONFIG_ROOT .. "/after")
if vim.env.NVIM_TEST_DISABLE_BINDINGS == "1" then
  local bindings = require("config.bindings")
  local set = bindings.set
  bindings.set = function(owner)
    return set(owner, {})
  end
end
require("config.context").initialize(selection)

-- Permission-warning floats must not obscure rendered-screen assertions.
dofile(vim.env.NVIM_CONFIG_ROOT .. "/tests/support/toolchain_sessions.lua")
