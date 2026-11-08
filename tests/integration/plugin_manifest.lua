local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
local sessions = vim.env.NVIM_WORKSPACE_ENABLED == "1"
require("config.context").initialize({ profiles = { "data" }, features = { sessions = sessions } })
local specs = require("config.specs").build()
local resolve = require("plugin_tools.graph").resolve
local local_graph = resolve(specs, { dev = { path = require("utils.platform").dev_plugin_root(), fallback = true } })
assert(not local_graph.packages["notification-tools.nvim"].managed)
assert(local_graph.nodes["python-tools.nvim"].owner == "python-tools.nvim")
assert((local_graph.nodes["workspace-tools.nvim"] ~= nil) == sessions)
if sessions then
  assert(local_graph.nodes["workspace-tools.nvim"].start == true)
  assert(local_graph.nodes["workspace-tools.nvim"].mount == "startup")
end
assert(local_graph.nodes["python-tools.nvim"].start == false)
assert(vim.deep_equal(local_graph.nodes["python-tools.nvim"].ft, { "python" }))
assert(local_graph.nodes["python-tools.nvim"].mount == "on-demand")
assert(local_graph.packages["python-tools.nvim"] ~= local_graph.packages["workspace-tools.nvim"])
assert(local_graph.nodes["python-tools.nvim"].declarations[1].origin == "languages.python.plugins")
assert(local_graph.nodes["notification-tools.nvim"].declarations[1].origin == "plugins.ui.notification-tools")
assert(not local_graph.nodes["lua-tools.nvim"], "Python-only selection must not activate Lua development")
local lua_graph = resolve(require("languages.lua").plugins, {
  dev = { path = require("utils.platform").dev_plugin_root(), fallback = true },
})
assert(lua_graph.nodes["lua-tools.nvim"].main == "lua_tools")
assert(lua_graph.nodes["lua-tools.nvim"].start == false)
assert(lua_graph.nodes["lua-tools.nvim"].mount == "on-demand")
assert(vim.deep_equal(lua_graph.nodes["lua-tools.nvim"].ft, { "lua" }))
assert(not lua_graph.nodes["lua-tools.nvim"].package.managed)
assert(lua_graph.nodes["lua-tools.nvim"].opts.nvim == true)
assert(local_graph.nodes["lsp-tools.nvim"].opts.lua == nil, "Lua libraries have one owner")
local provider = local_graph.nodes["nvim-lspconfig"]
assert(provider.parents["lsp-tools.nvim"] and not provider.roots)
assert(provider.owner == provider.id and local_graph.packages[provider.id].managed)
assert(provider.package.source == "https://github.com/neovim/nvim-lspconfig.git")
assert(provider.declarations[1].origin == "plugins.coding.nvim-lspconfig")
assert(provider.start == false and not provider.main and not provider.config)
assert(provider.mount == "on-demand")
assert(local_graph.nodes["keymap-tools.nvim"].dependencies["selection-tools.nvim"] == false)
assert(local_graph.nodes["lsp-tools.nvim"].dependencies["git-tools.nvim"] == false)
assert(local_graph.nodes["lsp-tools.nvim"].dependencies["selection-tools.nvim"] == false)
assert(local_graph.nodes["completion-tools.nvim"].dependencies["snippet-tools.nvim"] == false)
assert(local_graph.nodes["image-tools.nvim"].dependencies["git-tools.nvim"] == true)
assert(local_graph.nodes["selection-tools.nvim"].dependencies["image-tools.nvim"] == true)
assert(local_graph.nodes["lsp-tools.nvim"].dependencies[provider.id] == false)
assert(
  not local_graph.nodes["dap-tools.nvim"]
    and not local_graph.nodes["nvim-dap"]
    and not local_graph.nodes["task-tools.nvim"]
)
local remote = resolve(
  specs,
  { root = vim.env.NVIM_TEST_TMP .. "/packages", dev = { path = vim.env.NVIM_TEST_TMP .. "/missing", fallback = true } }
)
assert(remote.packages["notification-tools.nvim"].managed)
assert(remote.packages["notification-tools.nvim"].source == "https://github.com/Jacky-Lzx/notification-tools.nvim.git")
assert(remote.packages["image-tools.nvim"].managed, "Published image-tools must have a remote fallback")

for _, node in pairs(local_graph.nodes) do
  assert(node.event == nil and node.cmd == nil and node.lazy == nil and node.bootstrap == nil)
  assert(type(node.ft) == "table")
end
assert(not package.loaded.lazy and not package.loaded["image_tools.runtime"])
assert(not package.loaded["config.bindings"], "Resolving specs must not register personal keymaps")
print("Native manifest, independent Python ownership, feature gates, local preference and remote fallback passed")
