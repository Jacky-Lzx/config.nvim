local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)
for _, name in ipairs({ "completion-tools.nvim", "snippet-tools.nvim" }) do
  vim.opt.rtp:prepend(assert(vim.env.NVIM_TEST_PLUGIN_FIXTURES) .. "/" .. name)
end
local completion = require("integrations.completion.sources")
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
assert(vim.deep_equal(shown, { "buffer", "copilot", "lsp", "path", "snippets" }))
assert(integration.cycle(cmp, 1))
assert(vim.deep_equal(shown, { "buffer", "dictionary", "spell" }))
local opts = integration.options()
assert(opts.cmdline.enabled == true and opts.snippets.preset == "default")
assert(type(opts.providers.snippets.complete) == "function")
assert(type(opts.snippets.expand) == "function" and type(opts.snippets.jump) == "function")
assert(vim.deep_equal(opts.keymap["<Tab>"], { "accept", "snippet_forward", "fallback" }))
assert(not opts.providers.lazydev and opts.providers.copilot.score_offset < opts.providers.lsp.score_offset)
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
local policy_buf = vim.api.nvim_create_buf(true, false)
vim.bo[policy_buf].filetype = "python"
local ctx = { bufnr = policy_buf, row = 0, col = 0 }
local candidates = {
  { label = "text edit", kind = 1, _client_id = 11 },
  { label = "snippet edit", kind = 15, _client_id = 11, insertText = "${1:value}" },
  { label = "other server", kind = 1, _client_id = 12 },
  { label = "unknown server", kind = 1 },
}
local lookup = vim.lsp.get_client_by_id
vim.lsp.get_client_by_id = function(id)
  return { name = id == 11 and "noisy" or "other" }
end
assert(opts.providers.lsp.transform_items(ctx, candidates) == candidates)
integration.lsp_kind_filters.python = { noisy = { [1] = true } }
local filtered = opts.providers.lsp.transform_items(ctx, candidates)
assert(#filtered == 3 and filtered[1] == candidates[2] and filtered[1].insertText == "${1:value}")
vim.bo[policy_buf].filetype = "lua"
assert(opts.providers.lsp.transform_items(ctx, candidates) == candidates, "Filter leaked into another language")
integration.lsp_kind_filters.python = nil
vim.lsp.get_client_by_id = lookup
vim.bo[policy_buf].filetype = "python"
local code = opts.sources(ctx)
assert(
  vim.list_contains(code, "lsp") and not vim.list_contains(code, "dictionary") and not vim.list_contains(code, "spell")
)
vim.bo[policy_buf].filetype = "markdown"
local prose = opts.sources(ctx)
assert(vim.list_contains(prose, "dictionary") and vim.list_contains(prose, "spell"))
assert(vim.b[policy_buf].completion_tools_sources == nil, "Automatic policy must not freeze buffer defaults")
vim.bo[policy_buf].filetype = "tex"
local math, previous_tex = false, package.loaded["tex-tools"]
package.loaded["tex-tools"] = {
  in_math = function(options)
    assert(options.bufnr == policy_buf and vim.deep_equal(options.pos, { 0, 0 }))
    return math
  end,
}
assert(vim.list_contains(opts.sources(ctx), "dictionary"))
math = true
local formula = opts.sources(ctx)
assert(
  not vim.list_contains(formula, "dictionary")
    and not vim.list_contains(formula, "spell")
    and not vim.list_contains(formula, "copilot")
)
assert(vim.list_contains(formula, "lsp") and vim.list_contains(formula, "snippets"))
vim.b[policy_buf].completion_tools_sources = { "copilot", "dictionary" }
assert(vim.deep_equal(opts.sources(ctx), { "copilot", "dictionary" }), "Manual choices must survive context changes")
package.loaded["tex-tools"] = previous_tex
vim.api.nvim_del_augroup_by_name("ConfigCompletion")
vim.api.nvim_del_augroup_by_name("ConfigCompletionLayout")
print("Completion policy, persistent buffer-local sources and adapter checks passed")
