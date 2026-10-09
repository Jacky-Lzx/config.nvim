local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)

local completion = require("features.completion")
local integration = require("integrations.blink_completion")
assert(not package.loaded["blink.cmp.config"], "Loading completion behavior must not load Blink")
assert(vim.b.blink_sources == nil, "Loading completion behavior must not initialize buffer state")

local config = { default = { "lsp", "path", "buffer" }, providers = { lazydev = {} } }
local defaults = vim.deepcopy(config.default)
local first = vim.api.nvim_get_current_buf()
assert(vim.deep_equal(completion.code_sources(config), { "lazydev", "lsp", "path" }))
assert(vim.deep_equal(completion.code_sources({ providers = {} }), { "lsp", "path" }))
assert(vim.deep_equal(completion.cycle(config, 1), { "buffer" }))
assert(vim.deep_equal(completion.cycle(config, 1), { "snippets" }))
assert(vim.deep_equal(completion.cycle(config, 1), { "lazydev", "lsp", "path" }))
assert(vim.deep_equal(completion.cycle(config, 1), defaults))
assert(vim.deep_equal(completion.toggle_source(config, "copilot"), { "copilot", "lsp", "path", "buffer" }))
assert(vim.deep_equal(config.default, defaults), "Toggling a source changed provider defaults")

vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
assert(vim.deep_equal(completion.sources(config), defaults), "Completion choices leaked into another buffer")
assert(vim.deep_equal(completion.cycle(config, -1), { "lazydev", "lsp", "path" }))
vim.api.nvim_set_current_buf(first)
assert(vim.deep_equal(completion.sources(config), { "copilot", "lsp", "path", "buffer" }))
assert(not package.loaded["blink.cmp.config"], "Completion policy accessed Blink configuration")

local shown
package.preload["blink.cmp.config"] = function()
  return { sources = config }
end
local cmp = {
  show = function(opts)
    shown = opts.providers
    return true
  end,
}
assert(integration.toggle_source(cmp, "copilot"))
assert(vim.deep_equal(shown, defaults))
assert(integration.cycle(cmp, 1))
assert(vim.deep_equal(shown, { "buffer" }))
print("Completion policy isolation and Blink adapter checks passed")
