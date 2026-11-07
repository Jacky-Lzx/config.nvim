local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
require("config.context").initialize({ profiles = { "data" }, features = { debugging = true } })
local platform = require("utils.platform")
local paths = { ruff = "/fixture/ruff" }
platform.executable = function(name)
  return paths[name]
end
platform.debugpy_python = function()
  return "/fixture/debugpy/python"
end
local before = #vim.api.nvim_get_autocmds({})
local inspect = require("config.inspect")
local info = inspect.snapshot()
assert(info.paths.checkout == require("utils.paths").root)
assert(info.paths.config == vim.fn.stdpath("config"))
assert(info.paths.dev_plugins == platform.dev_plugin_root())
assert(vim.deep_equal(info.selection.profiles, { "data" }))
assert(info.selection.features.debugging and not info.selection.features.ai)
assert(vim.deep_equal(info.languages.servers, { "basedpyright" }))
assert(#info.lsp.enabled_servers == 0, "Selected servers are not necessarily enabled yet")
assert(info.tools[1].name == "ruff" and info.tools[1].path == "/fixture/ruff")
assert(not info.tools[2].available and info.tools[2].path == nil)
assert(info.tools[3].name == "debugpy" and info.tools[3].path == "/fixture/debugpy/python")
assert(not info.plugins.initialized and #info.plugins.entries == 0)
assert(not package.loaded.lazy and not package.loaded["lazy.core.config"])
assert(#vim.api.nvim_get_autocmds({}) == before, "Inspection must not initialize native LSP behavior")

local original_enabled = vim.lsp.is_enabled
before = #vim.api.nvim_get_autocmds({})
vim.lsp.is_enabled = function(name)
  return name == "basedpyright"
end
local plugins = {
  ["pairs.nvim"] = { dir = "/fixture/dev/pairs.nvim", dev = true, package = { managed = false } },
  ["remote.nvim"] = {
    dir = "/fixture/plugin-tools/remote.nvim",
    package = { managed = true, source = "https://example.test/remote.git" },
  },
}
package.loaded["config.plugins"] = {
  manager = {
    graph = { nodes = plugins },
    states = { ["pairs.nvim"] = { phase = "ready" }, ["remote.nvim"] = { phase = "mounted" } },
  },
}
info = inspect.snapshot()
assert(vim.deep_equal(info.lsp.enabled_servers, { "basedpyright" }))
assert(info.plugins.initialized and #info.plugins.entries == 2)
local local_plugin, remote = info.plugins.entries[1], info.plugins.entries[2]
assert(local_plugin.name == "pairs.nvim" and local_plugin.directory == plugins["pairs.nvim"].dir)
assert(local_plugin.source == "local" and local_plugin.development and local_plugin.loaded)
assert(remote.source == "git" and not remote.development and not remote.loaded)
info.selection.profiles[1] = "changed"
info.languages.servers[1] = "changed"
info.tools[1].path = "changed"
local_plugin.directory = "changed"
local fresh = inspect.snapshot()
assert(fresh.selection.profiles[1] == "data" and fresh.languages.servers[1] == "basedpyright")
assert(fresh.tools[1].path == "/fixture/ruff" and fresh.plugins.entries[1].directory == "/fixture/dev/pairs.nvim")
paths.ruff = "/fixture/updated/ruff"
assert(inspect.snapshot().tools[1].path == paths.ruff, "Tool discovery must stay live")

local reports = {}
for _, kind in ipairs({ "start", "info", "ok", "warn", "error" }) do
  vim.health[kind] = function(message)
    reports[#reports + 1] = message
  end
end
require("config.health").check()
assert(#reports == 3 and reports[1] == "Neovim configuration", "Healthy output stays compact")
assert(vim.list_contains(reports, "Details: :ConfigInfo"))
assert(not table.concat(reports, "\n"):find("ruff", 1, true), "Tool details belong to their owning plugin")
local context = require("config.context")
local resolve = context.resolve
context.resolve = function()
  error("fixture: conflicting language declarations")
end
reports = {}
require("config.health").check()
context.resolve = resolve
assert(table.concat(reports, "\n"):find("conflicting language declarations", 1, true))
assert(not table.concat(reports, "\n"):find("are valid", 1, true), "Invalid declarations must not report success")
assert(not package.loaded["tex-tools"], "Configuration health must not initialize the viewer plugin")
vim.lsp.is_enabled = original_enabled
assert(#vim.api.nvim_get_autocmds({}) == before and not package.loaded.lazy)
print("ConfigInfo snapshots, live paths, compact health and invalid declarations passed")
