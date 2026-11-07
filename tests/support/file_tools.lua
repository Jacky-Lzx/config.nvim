-- Configuration-specific assertions and physical keys for file-tools' PTY scenario.
-- The external harness owns filesystem operations and rendered workflow results.
local M = {}

function M.before_open()
  local plugins = require("config.plugins").nodes()
  assert(plugins["file-tools.nvim"], "File-tools is not selected")
  assert(not package.loaded["file_tools.tree"], "File tree loaded before first use")
  for _, name in ipairs({ "nvim-tree.lua", "nvim-lsp-file-operations", "yazi.nvim" }) do
    assert(not plugins[name], "Replaced file plugin is still configured: " .. name)
  end
end

function M.after_open()
  assert(require("config.plugins").initialized("file-tools.nvim"), "File command registration is missing")
  assert(not package.loaded["file_tools.tree"], "Capabilities initialized the tree")
  local capabilities = vim.lsp.config["*"].capabilities
  assert(capabilities.workspace.fileOperations.willRename)
  assert(capabilities.textDocument.completion.completionItem.snippetSupport)
end

function M.actions()
  local resolver = dofile(assert(vim.env.NVIM_CONFIG_ROOT) .. "/tests/support/actions.lua")
  local actions = {}
  for key, id in pairs({
    toggle = "files.tree",
    files = "selection.files",
    reveal = "files.reveal",
    cwd = "files.cwd",
  }) do
    actions[key] = resolver.input(id)
  end
  return actions
end

return M
