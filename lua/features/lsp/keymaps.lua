local M = {}

function M.attach(buffer)
  local function map(key, action, description)
    vim.keymap.set("n", key, action, { buffer = buffer, desc = "[LSP] " .. description })
  end
  map("<leader>d", vim.diagnostic.open_float, "Show diagnostic")
  map("<leader>gk", vim.lsp.buf.signature_help, "Signature help")
  map("<leader>gf", vim.lsp.buf.format, "Format")
  map("<leader>rn", vim.lsp.buf.rename, "Rename")
  map("<leader>gr", vim.lsp.buf.references, "References")
  map("<leader>gt", vim.lsp.buf.type_definition, "Type definition")
  map("<leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
  map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
  map("<leader>wl", function()
    vim.print(vim.lsp.buf.list_workspace_folders())
  end, "List workspace folders")
end

return M
