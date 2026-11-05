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
assert(not local_graph.nodes["nvim-dap"] and not local_graph.nodes["task-tools.nvim"])
local remote = resolve(
  specs,
  { root = vim.env.NVIM_TEST_TMP .. "/packages", dev = { path = vim.env.NVIM_TEST_TMP .. "/missing", fallback = true } }
)
assert(remote.packages["notification-tools.nvim"].managed)
assert(remote.packages["notification-tools.nvim"].source == "git@github.com:Jacky-Lzx/notification-tools.nvim.git")
assert(not remote.packages["image-tools.nvim"].managed, "Unpublished local-only plugins acquired a remote fallback")
for _, node in pairs(local_graph.nodes) do
  assert(node.event == nil and node.cmd == nil and node.ft == nil and node.lazy == nil)
end
assert(not package.loaded.lazy and not package.loaded["image_tools.runtime"])
print("Native manifest, Python child ownership, feature gates, local preference and remote fallback passed")
