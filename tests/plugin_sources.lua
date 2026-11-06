local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
require("config.context").initialize({
  profiles = { "base", "data", "writing" },
  features = { tasks = true, sessions = true },
})
local resolve = require("plugin_tools.graph").resolve
local published = {
  "completion-tools.nvim",
  "git-tools.nvim",
  "image-tools.nvim",
  "input-tools.nvim",
  "lsp-tools.nvim",
  "notification-tools.nvim",
  "pairs.nvim",
  "selection-tools.nvim",
  "task-tools.nvim",
  "tex-tools.nvim",
  "theme-tools.nvim",
  "toolchain-tools.nvim",
  "ui-tools.nvim",
  "workspace-tools.nvim",
}
local all_specs = require("config.specs").build()
local development_root = require("utils.platform").dev_plugin_root()
local installed_root = vim.env.NVIM_TEST_TMP .. "/packages"
local development = resolve(all_specs, { dev = { path = development_root, fallback = true } })
local fallback = resolve(all_specs, {
  root = installed_root,
  dev = { path = vim.env.NVIM_TEST_TMP .. "/missing", fallback = true },
})
for _, id in ipairs(published) do
  local node, package = development.nodes[id], development.packages[id]
  assert(node.dev and not package.managed and node.dir == development_root .. "/" .. id, id)
  assert(package.source:match("github.com[:/]Jacky%-Lzx/" .. vim.pesc(id) .. "%.git$"), id)
  assert(fallback.packages[id].managed and fallback.packages[id].source == package.source, id)
  assert(fallback.nodes[id].dir == installed_root .. "/" .. id, id)
end
for _, id in ipairs({
  "debug-tools.nvim",
  "editing-tools.nvim",
  "file-tools.nvim",
  "keymap-tools.nvim",
  "motion-tools.nvim",
  "snippet-tools.nvim",
}) do
  assert(not fallback.packages[id].managed and fallback.packages[id].source == nil, id)
  assert(fallback.nodes[id].dir == development_root .. "/" .. id, id)
end
assert(fallback.nodes["workspace-tools.python"].owner == "workspace-tools.nvim")
assert(fallback.nodes["workspace-tools.python"].dir == fallback.nodes["workspace-tools.nvim"].dir)
assert(not package.loaded["config.bindings"], "Resolving sources must not initialize plugins")
print("Published plugin sources: all 14 prefer development checkouts and resolve managed GitHub fallbacks")
