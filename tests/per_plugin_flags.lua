local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
local resolve = require("plugin_tools.graph").resolve
local build = require("config.specs").build
local function graph()
  return resolve(build(), { dev = { path = require("utils.platform").dev_plugin_root(), fallback = true } })
end
local formatter = require("plugins.third_party.conform")[1]
assert(formatter.enabled == true and graph().nodes["conform.nvim"])
formatter.enabled = false
local disabled = graph()
assert(not disabled.nodes["conform.nvim"], "Disabling one plugin kept option-only contributions alive")
assert(disabled.nodes["nvim-lint"] and disabled.nodes["vim-wakatime"])
assert(disabled.nodes["lsp-tools.nvim"] and disabled.nodes["theme-tools.nvim"])
formatter.enabled = true
local crates = require("plugins.disabled.crates")[1]
assert(crates.enabled == false)
crates.enabled = true
local restored = graph()
assert(restored.nodes["crates.nvim"], "A declaration's enabled flag did not enable that plugin")
assert(restored.nodes["conform.nvim"] and not restored.nodes["render-markdown.nvim"])
assert(restored.nodes["nvim-lspconfig"].parents["lsp-tools.nvim"])
crates.enabled = false
assert(not graph().nodes["crates.nvim"])
print("Per-plugin flags independently disable enabled plugins and restore disabled declarations")
