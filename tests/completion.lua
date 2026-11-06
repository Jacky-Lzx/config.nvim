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
for _, expected in ipairs({ { "buffer", "dictionary", "spell" }, { "snippets" }, { "lsp", "path" }, defaults }) do
  assert(vim.deep_equal(completion.cycle(config, 1), expected))
  assert(vim.deep_equal(completion.active_sources(config), expected), "cycle must survive subsequent typing")
end
local sources = completion.toggle_source(config, "buffer")
assert(not vim.list_contains(sources, "buffer"))
assert(vim.deep_equal(config.default, defaults))
assert(config.providers.copilot)
local without_copilot = completion.toggle_source(config, "copilot")
assert(not vim.list_contains(without_copilot, "copilot"))
assert(vim.list_contains(completion.toggle_source(config, "copilot"), "copilot"))
assert(not pcall(completion.toggle_source, config, "unknown"))
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
assert(vim.deep_equal(shown, { "buffer", "copilot", "lsp", "path", "snippets", "dictionary", "spell" }))
assert(integration.cycle(cmp, 1))
assert(vim.deep_equal(shown, { "buffer", "dictionary", "spell" }))
local opts = integration.options()
assert(opts.cmdline.enabled == true and opts.snippets.preset == "default")
assert(type(opts.providers.snippets.complete) == "function")
assert(type(opts.snippets.expand) == "function" and type(opts.snippets.jump) == "function")
assert(vim.deep_equal(opts.keymap["<Tab>"], { "accept", "snippet_forward", "fallback" }))
assert(not opts.providers.lazydev and opts.providers.copilot.score_offset == 100)
assert(type(opts.keymap["<A-i>"][1]) == "function")
assert(vim.deep_equal(opts.copilot.command, { "copilot-language-server", "--stdio" }))
assert(opts.copilot.max_items == 3 and opts.copilot.debounce_ms == 150)
assert(opts.providers.copilot.timeout_ms == 10000)
assert(opts.providers.dictionary.score_offset == 5 and opts.providers.spell.score_offset == 10)
assert(opts.dictionary.min_keyword_length == 3 and opts.dictionary.max_items == 10)
assert(opts.dictionary.files[1] == require("utils.paths").config("configs", "dictionary.txt"))
assert(opts.spell.sort == "match")
assert(type(opts.cmdline.get_anchor) == "function" and opts.cmdline.keymap["<CR>"] == nil)
for _, maps in ipairs({ opts.keymap, opts.cmdline.keymap }) do
  for key, method in pairs({ ["<A-d>"] = "select_next", ["<A-u>"] = "select_prev" }) do
    local called = false
    local paging = {}
    paging[method] = function(options)
      assert(options.count == 5 and options.wrap == false)
      called = true
      return true
    end
    assert(maps[key][1](paging) and called, "Paging must stop at candidate boundaries")
  end
end
assert(not package.loaded["completion-tools"] and not package.loaded["blink.cmp"], "Policy must remain pure")
integration.setup()
vim.api.nvim_exec_autocmds("User", { pattern = "ConfigReady" })
vim.api.nvim_exec_autocmds("User", { pattern = "SnippetToolsReady" })
assert(not package.loaded.completion_tools, "Readiness events must not import an unused completion engine")
local refreshed = 0
package.loaded.completion_tools = {
  refresh_keymaps = function()
    refreshed = refreshed + 1
  end,
}
vim.api.nvim_exec_autocmds("User", { pattern = "SnippetToolsReady" })
assert(refreshed == 1, "A loaded engine must refresh when snippet bindings become available")
package.loaded.completion_tools = nil
vim.api.nvim_del_augroup_by_name("ConfigCompletion")
vim.api.nvim_del_augroup_by_name("ConfigCompletionLayout")
print("Completion policy, persistent buffer-local sources and adapter checks passed")
