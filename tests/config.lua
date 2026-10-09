local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)
vim.env.PROF = nil

local before = #vim.api.nvim_get_autocmds({})
local config = require("config")
assert(type(config.setup) == "function" and type(config.info) == "function")
assert(#vim.api.nvim_get_autocmds({}) == before, "Requiring config must not register editor behavior")
assert(vim.fn.exists(":ConfigInfo") == 0, "Commands belong to setup, not module loading")
assert(not package.loaded["core.options"] and not package.loaded["features.lsp"])
assert(not package.loaded.lazy and not package.loaded["snacks.profiler"])

local version = vim.version()
local info = config.info()
assert(info.version == ("%d.%d.%d"):format(version.major, version.minor, version.patch))
for _, kind in ipairs({ "config", "data", "state", "cache" }) do
  assert(info.paths[kind] == vim.fn.stdpath(kind), kind)
end
info.paths.config = "/changed"
assert(config.info().paths.config == vim.fn.stdpath("config"), "ConfigInfo must return a fresh snapshot")

-- Reject unsupported Neovim versions before installing any editor behavior.
local has = vim.fn.has
vim.fn.has = function(feature)
  return feature == "nvim-0.12" and 0 or has(feature)
end
local ok, err = pcall(config.setup)
vim.fn.has = has
assert(not ok and tostring(err):find("requires Neovim 0.12 or newer", 1, true))
assert(#vim.api.nvim_get_autocmds({}) == before and vim.fn.exists(":ConfigInfo") == 0)
assert(not package.loaded["core.options"] and not package.loaded["config.lazy"])

-- Exercise the actual entry point while keeping plugin bootstrap out of this test.
local bootstrapped = false
package.preload["config.lazy"] = function()
  assert(vim.g.mapleader == " " and vim.g.maplocalleader == " ")
  assert(vim.g.loaded_netrw == 1 and vim.g.loaded_netrwPlugin == 1)
  assert(vim.fn.exists(":ConfigInfo") == 2 and vim.fn.exists(":Titlecase") == 2)
  assert(vim.fn.maparg("jk", "i") == "<Esc>")
  assert(#vim.api.nvim_get_autocmds({ group = "ConfigCore", event = "FileType" }) == 1)
  assert(#vim.api.nvim_get_autocmds({ group = "ConfigLsp", event = "LspAttach" }) == 1)
  assert(vim.diagnostic.config().virtual_lines == false)
  bootstrapped = true
  return {}
end
dofile(root .. "/init.lua")
assert(bootstrapped, "The root entry point must invoke config.setup")
for name in pairs(package.loaded) do
  assert(not name:match("^config%.legacy[%.]?"), "Startup loaded an archived module: " .. name)
end
assert(not package.loaded["snacks.profiler"], "Profiling must remain opt-in")
assert(not package.loaded.lazy and not package.loaded.snacks, "Core setup must remain plugin-independent")

-- Opting into profiling uses the installed Snacks runtime and its startup hook.
local profiling = require("extra.profiling")
local started = false
package.preload["snacks.profiler"] = function()
  return {
    startup = function(opts)
      assert(opts.startup.event == "VimEnter")
      started = true
    end,
  }
end
vim.env.PROF = "1"
profiling.setup()
assert(started)
assert(vim.list_contains(vim.opt.runtimepath:get(), vim.fn.stdpath("data") .. "/lazy/snacks.nvim"))
print("Configuration entry point and profiling lifecycle checks passed")
