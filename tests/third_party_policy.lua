local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
local policy = require("config.third_party")
local original = policy.enabled
local specs = {
  {
    id = "owned",
    source = "Jacky-Lzx/example",
    dependencies = { "provider" },
    children = { { id = "provider", source = "neovim/nvim-lspconfig" } },
  },
  { id = "foreign", source = "other/plugin", main = "foreign" },
  { id = "foreign", opts = { extension = true } },
  { id = "already-disabled", source = "other/disabled", enabled = false },
}
local before = #vim.api.nvim_get_autocmds({})
policy.enabled = false
local filtered = policy.apply(vim.deepcopy(specs))
local graph = require("plugin_tools.graph").resolve(filtered)
assert(graph.nodes.owned and graph.nodes.provider.parents.owned)
assert(not graph.nodes.foreign, "Option-only contributions recreated a disabled package")
assert(filtered[2].enabled == false and filtered[3].enabled == false)
policy.enabled = true
local restored = require("plugin_tools.graph").resolve(policy.apply(vim.deepcopy(specs)))
assert(restored.nodes.foreign.opts.extension == true)
assert(not restored.nodes["already-disabled"], "Restoration enabled an originally disabled plugin")
assert(#vim.api.nvim_get_autocmds({}) == before and not package.loaded.foreign)
policy.enabled = original
print(
  "Third-party policy: overlays cannot recreate disabled packages; owned dependencies and original enable flags survive"
)
