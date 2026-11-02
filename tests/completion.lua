local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)
local completion = require("features.completion")
local integration = require("integrations.completion")
assert(not package.loaded["completion-tools"] and not package.loaded["blink.cmp"])
assert(vim.b.completion_tools_sources == nil)
local config = integration.source_config
local defaults = vim.deepcopy(config.default)
local first = vim.api.nvim_get_current_buf()
assert(vim.deep_equal(completion.code_sources(), { "lsp", "path" }))
for _, expected in ipairs({ { "buffer" }, { "snippets" }, { "lsp", "path" }, defaults }) do
  assert(vim.deep_equal(completion.cycle(config, 1), expected))
  assert(vim.deep_equal(completion.active_sources(config), expected), "cycle must survive subsequent typing")
end
local sources = completion.toggle_source(config, "buffer")
assert(not vim.list_contains(sources, "buffer"))
assert(vim.deep_equal(config.default, defaults))
assert(not pcall(completion.toggle_source, config, "copilot"), "Unadapted source must not be enabled")
vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
assert(vim.deep_equal(completion.sources(config), defaults))
assert(vim.deep_equal(completion.cycle(config, -1), { "lsp", "path" }))
vim.api.nvim_set_current_buf(first)
assert(not vim.list_contains(completion.sources(config), "buffer"))
local shown
local cmp = {
  hide = function() end,
  show = function(opts)
    shown = opts.sources
    return true
  end,
}
assert(integration.toggle_source(cmp, "buffer"))
assert(vim.deep_equal(shown, { "buffer", "lsp", "path", "snippets" }))
assert(integration.cycle(cmp, 1))
assert(vim.deep_equal(shown, { "buffer" }))
local opts = integration.options()
assert(opts.cmdline.enabled == false and opts.snippets.preset == "luasnip")
assert(
  not opts.providers.lazydev
    and not opts.providers.dictionary
    and not opts.providers.spell
    and not opts.providers.copilot
)
assert(not package.loaded["completion-tools"] and not package.loaded["blink.cmp"], "Policy must remain pure")
print("Completion policy, persistent buffer-local sources and adapter checks passed")
