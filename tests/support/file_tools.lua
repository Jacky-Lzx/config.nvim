-- Configuration-specific assertions and Lua API invocations for file-tools' PTY scenario.
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
  return {
    toggle = ':lua require("file_tools").toggle()\r',
    files = ':lua require("selection_tools").files()\r',
    reveal = ':lua require("file_tools").find()\r',
    cwd = ':lua require("file_tools").open({ root = vim.fn.getcwd() })\r',
  }
end

return M
