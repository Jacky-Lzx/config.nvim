local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
require("config.context").initialize({ profiles = { "data" }, features = { sessions = false } })
local specs = require("config.specs").build()
local resolve = require("plugin_tools.graph").resolve
local local_graph = resolve(specs, { dev = { path = require("utils.platform").dev_plugin_root(), fallback = true } })
assert(not local_graph.packages["notification-tools.nvim"].managed)
assert(local_graph.nodes["workspace-tools.python"].owner == "workspace-tools.nvim")
assert(local_graph.nodes["workspace-tools.nvim"].start == false)
assert(local_graph.nodes["workspace-tools.python"].start == true)
assert(local_graph.nodes["workspace-tools.python"].declarations[1].origin == "languages.python.plugins")
assert(local_graph.nodes["notification-tools.nvim"].declarations[1].origin == "plugins.ui.notification-tools")
local provider = local_graph.nodes["nvim-lspconfig"]
assert(provider.parents["lsp-tools.nvim"] and not provider.roots)
assert(provider.owner == provider.id and local_graph.packages[provider.id].managed)
assert(provider.package.source == "https://github.com/neovim/nvim-lspconfig.git")
assert(provider.declarations[1].origin == "plugins.third_party.nvim-lspconfig")
assert(provider.start == false and not provider.main and not provider.config)
assert(local_graph.nodes["lsp-tools.nvim"].dependencies[provider.id] == false)
assert(not local_graph.nodes["nvim-dap"] and not local_graph.nodes["task-tools.nvim"])
local remote = resolve(
  specs,
  { root = vim.env.NVIM_TEST_TMP .. "/packages", dev = { path = vim.env.NVIM_TEST_TMP .. "/missing", fallback = true } }
)
assert(remote.packages["notification-tools.nvim"].managed)
assert(remote.packages["notification-tools.nvim"].source == "git@github.com:Jacky-Lzx/notification-tools.nvim.git")
assert(remote.packages["image-tools.nvim"].managed, "Published image-tools must have a remote fallback")

for _, node in pairs(local_graph.nodes) do
  assert(node.event == nil and node.cmd == nil and node.ft == nil and node.lazy == nil and node.bootstrap == nil)
end
assert(not package.loaded.lazy and not package.loaded["image_tools.runtime"])
assert(not package.loaded["config.bindings"], "Resolving specs must not register personal keymaps")
print("Native manifest, Python child ownership, feature gates, local preference and remote fallback passed")
