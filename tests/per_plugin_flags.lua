local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
local resolve = require("plugin_tools.graph").resolve
local build = require("config.specs").build
local formatter = require("plugins.coding.conform")[1]
assert(formatter.enabled == false)
formatter.enabled = true
local graph = resolve(build(), { dev = { path = require("utils.platform").dev_plugin_root(), fallback = true } })
assert(graph.nodes["conform.nvim"], "A declaration's enabled flag did not enable that plugin")
assert(not graph.nodes["nvim-lint"] and not graph.nodes["render-markdown.nvim"])
assert(graph.nodes["nvim-lspconfig"].parents["lsp-tools.nvim"])
formatter.enabled = false
local disabled = resolve(build(), { dev = { path = require("utils.platform").dev_plugin_root(), fallback = true } })
assert(not disabled.nodes["conform.nvim"], "Disabling one plugin kept option-only contributions alive")
assert(disabled.nodes["lsp-tools.nvim"] and disabled.nodes["theme-tools.nvim"])
print("Per-plugin enabled flags independently restore and disable one plugin without a global policy")
