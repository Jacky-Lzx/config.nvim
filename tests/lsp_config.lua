local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)

local lsp = require("plugins.coding.lsp-tools")[1]
local provider = assert(lsp.children[1])
assert(provider.id == "nvim-lspconfig" and provider.source == "neovim/nvim-lspconfig")
assert(not provider.main and not provider.config and not provider.opts)
assert(lsp.opts.server_activation == "filetype", "Servers must activate only when their filetypes are opened")
assert(not lsp.event and vim.list_contains(lsp.after, "toolchain-tools.nvim"))
assert(vim.list_contains(lsp.dependencies, "nvim-lspconfig"))
assert(not vim.list_contains(lsp.dependencies, "completion-tools.nvim"), "LSP must not initialize the completion UI")
assert(vim.list_contains(lsp.dependencies, "file-tools.nvim"))
assert(vim.list_contains(lsp.dependencies, "toolchain-tools.nvim"))
local selected = require("languages").current().servers
assert(vim.tbl_count(lsp.opts.servers) == #selected)
for _, name in ipairs(selected) do
  assert(lsp.opts.servers[name] == true, "Profile server missing from lsp-tools: " .. name)
  assert(lsp.opts.server_filetypes[name] ~= nil, "Profile server has no activation hint: " .. name)
end
local completion_spec = require("plugins.coding.completion.core")[1]
assert(completion_spec.main == "completion-tools" and not completion_spec.event and not completion_spec.module)
local original_completion = package.loaded["completion-tools"]
local original_files = package.loaded.file_tools
local file_capabilities = {
  workspace = {
    fileOperations = {
      dynamicRegistration = true,
      didCreate = true,
      willCreate = true,
      didRename = true,
      willRename = true,
      didDelete = true,
      willDelete = true,
    },
  },
}
package.loaded.file_tools = {
  capabilities = function()
    return file_capabilities
  end,
}
local original_config, original_enable = vim.lsp.config, vim.lsp.enable
local original_manager = package.loaded["lsp-tools"]
local configured, setup, enabled = false, false, false
local capabilities = { textDocument = { completion = { completionItem = { snippetSupport = true } } } }
package.loaded["completion-tools"] = {
  setup = function(opts)
    assert(opts == completion_spec.opts)
    setup = true
  end,
  get_lsp_capabilities = function(override, defaults)
    assert(not setup, "Capabilities must be available before completion setup")
    assert(override == nil and defaults == nil, "completion-tools includes Neovim defaults")
    return capabilities
  end,
}
package.loaded["completion_tools.bootstrap"] = { setup = package.loaded["completion-tools"].setup }
vim.lsp.config = function(name, opts)
  assert(name == "*")
  assert(vim.deep_equal(opts.capabilities.textDocument, capabilities.textDocument))
  assert(vim.deep_equal(opts.capabilities.workspace.fileOperations, file_capabilities.workspace.fileOperations))
  assert(capabilities.workspace == nil, "Merging file capabilities mutated completion defaults")
  configured = true
end
package.loaded["lsp-tools"] = {
  setup = function(opts)
    assert(configured, "capabilities must be finalized before configuring lsp-tools")
    assert(opts == lsp.opts)
    enabled = true
  end,
  inspect = function() end,
  toggle_outline = function() end,
  open_outline = function() end,
}
vim.lsp.enable = function()
  assert(configured, "capabilities must be finalized before enabling servers")
  error("Plugin specs must leave activation to lsp-tools")
end
lsp.config({ opts = lsp.opts, dir = lsp.dir })
assert(configured and enabled and not setup, "LSP setup must not initialize interactive completion")
completion_spec.config({ opts = completion_spec.opts, dir = completion_spec.dir })
assert(setup, "Completion still initializes through its input-event configuration")
package.loaded["lsp-tools"] = original_manager

-- Editor mappings must not overwrite completion capabilities.
vim.lsp.config = function()
  error("features.lsp must not overwrite capabilities")
end
vim.lsp.enable = function()
  error("features.lsp must leave server activation to the plugin configuration")
end
local mappings = require("features.lsp")
for _, key in ipairs({ "grn", "gra", "grr", "gri" }) do
  vim.keymap.set("n", key, "<Nop>")
end
mappings.setup()
mappings.setup()
for _, key in ipairs({ "grn", "gra", "grr", "gri" }) do
  assert(vim.fn.maparg(key, "n") == "", "Native LSP mapping policy must run without Snacks")
end
assert(not package.loaded.snacks)
assert(#vim.api.nvim_get_autocmds({ group = "ConfigLsp", event = "LspAttach" }) == 1)
assert(not package.loaded.conform, "LSP setup must not load formatters")

assert(vim.lsp.inlay_hint.is_enabled(), "Inlay hints must default to enabled for the session")
local hints_before_toggle = vim.api.nvim_create_buf(true, false)
assert(vim.lsp.inlay_hint.is_enabled({ bufnr = hints_before_toggle }))
vim.lsp.inlay_hint.enable(false)
mappings.setup()
assert(not vim.lsp.inlay_hint.is_enabled(), "Repeated setup must preserve the manual toggle")
local hints_after_toggle = vim.api.nvim_create_buf(true, false)
local get_client = vim.lsp.get_client_by_id
vim.lsp.get_client_by_id = function()
  return {
    supports_method = function(_, method, buffer)
      assert(method == "textDocument/inlayHint" and buffer == hints_after_toggle)
      return true
    end,
  }
end
vim.api.nvim_exec_autocmds("LspAttach", { group = "ConfigLsp", buffer = hints_after_toggle, data = { client_id = 1 } })
vim.lsp.get_client_by_id = get_client
for _, buffer in ipairs({ hints_before_toggle, hints_after_toggle }) do
  assert(not vim.lsp.inlay_hint.is_enabled({ bufnr = buffer }), "LSP attach must preserve disabled hints")
end
vim.lsp.inlay_hint.enable(true)
for _, buffer in ipairs({ hints_before_toggle, hints_after_toggle, vim.api.nvim_create_buf(true, false) }) do
  assert(vim.lsp.inlay_hint.is_enabled({ bufnr = buffer }), "Re-enabling hints must cover old and new buffers")
end

local attached = vim.api.nvim_create_buf(true, false)
local unrelated = vim.api.nvim_get_current_buf()
local formatted
local format = function()
  formatted = vim.api.nvim_get_current_buf()
end
vim.keymap.set("n", "<leader>gf", format, { desc = "Format" })
vim.api.nvim_exec_autocmds("LspAttach", { buffer = attached, data = { client_id = 1 } })
vim.api.nvim_buf_call(attached, function()
  local mapping = vim.fn.maparg("<leader>gf", "n", false, true)
  assert(mapping.buffer == 0 and mapping.callback == format, "LSP attach replaced the shared format mapping")
  mapping.callback()
  assert(vim.fn.maparg("<leader>rn", "n", false, true).buffer == 1)
  local previous = package.loaded["lsp-tools"]
  local renamed
  package.loaded["lsp-tools"] = {
    rename = function()
      renamed = vim.api.nvim_get_current_buf()
    end,
  }
  vim.fn.maparg("<leader>rn", "n", false, true).callback()
  assert(renamed == attached, "Rename mapping must invoke lsp-tools in the attached buffer")
  package.loaded["lsp-tools"] = previous
end)
assert(formatted == attached)
vim.api.nvim_buf_call(unrelated, function()
  assert(vim.fn.maparg("<leader>gf", "n", false, true).callback == format)
  assert(vim.fn.maparg("<leader>rn", "n") == "")
end)
vim.lsp.config, vim.lsp.enable = original_config, original_enable
package.loaded["completion-tools"] = original_completion
package.loaded.file_tools = original_files
vim.api.nvim_del_augroup_by_name("ConfigLsp")

local editing = require("plugins.editing.editing-tools")[1]
assert(editing.id == "editing-tools.nvim" and editing.main == "editing_tools")
assert(editing.source == "Jacky-Lzx/editing-tools.nvim" and editing.dev == true)
assert(editing.opts and not editing.event and not editing.cmd)
assert(not vim.list_contains(editing.dependencies or {}, "nvim-treesitter/nvim-treesitter-textobjects"))
print("LSP capability ordering and buffer-local feature checks passed")
