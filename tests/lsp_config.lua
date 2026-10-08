local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)

local lsp = require("plugins.coding.nvim-lspconfig")[1]
assert(vim.list_contains(lsp.dependencies, "saghen/blink.cmp"))
local blink = require("plugins.coding.completion.core")[1]
local original_blink = package.loaded["blink.cmp"]
local original_config, original_enable = vim.lsp.config, vim.lsp.enable
local configured, setup, enabled = false, false, false
local capabilities = { textDocument = { completion = { completionItem = { snippetSupport = true } } } }
package.loaded["blink.cmp"] = {
  setup = function(opts)
    assert(opts == blink.opts)
    setup = true
  end,
  get_lsp_capabilities = function(override, defaults)
    assert(setup, "Blink must load before LSP configuration")
    assert(override == nil and defaults == true, "include Neovim defaults")
    return capabilities
  end,
}
vim.lsp.config = function(name, opts)
  assert(name == "*" and opts.capabilities == capabilities)
  configured = true
end
vim.lsp.enable = function(servers)
  assert(configured, "capabilities must be finalized before enabling servers")
  assert(servers == lsp.opts.servers)
  enabled = true
end
(blink.config or function(_, opts)
  require("blink.cmp").setup(opts)
end)(nil, blink.opts)
assert(not configured, "Blink setup must not separately configure capabilities")
lsp.config(nil, lsp.opts)
assert(configured and enabled)

-- Editor mappings must not overwrite completion capabilities.
local original_schedule = vim.schedule
vim.schedule = function() end
vim.lsp.config = function()
  error("lua/config/lsp.lua must not overwrite capabilities")
end
dofile(root .. "/lua/config/lsp.lua")
vim.schedule = original_schedule
vim.lsp.config, vim.lsp.enable = original_config, original_enable
package.loaded["blink.cmp"] = original_blink
vim.api.nvim_del_augroup_by_name("UserLspConfig")

local original_snacks = package.loaded["trouble.sources.snacks"]
local picker, opened = {}, false
package.loaded["trouble.sources.snacks"] = {
  open = function(actual, opts)
    assert(actual == picker and opts.type == "smart")
    opened = true
  end,
}
local snacks = require("plugins.navigation.trouble")[2].specs
local opts = snacks.opts(nil, { picker = { enabled = true } })
assert(not opened, "configuring Snacks must not open Trouble")
assert(opts.picker.enabled)
assert(opts.picker.win.input.keys["<c-t>"][1] == "trouble_open")
opts.picker.actions.trouble_open.action(picker)
assert(opened, "picker action must open Trouble, not just create a wrapper")
package.loaded["trouble.sources.snacks"] = original_snacks

local mini = require("plugins.editing.mini-ai")[1]
assert(vim.list_contains(mini.dependencies, "nvim-treesitter/nvim-treesitter-textobjects"))
