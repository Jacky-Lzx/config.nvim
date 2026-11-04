local M = {}

function M.attach(buffer)
  local function map(key, action, description)
    vim.keymap.set("n", key, action, { buffer = buffer, desc = "[LSP] " .. description })
  end

  map("<leader>d", function()
    vim.diagnostic.open_float({ scope = "line", focus = true })
  end, "Show line diagnostics")
  map("<leader>gk", vim.lsp.buf.signature_help, "Signature help")
  map("gK", vim.lsp.buf.signature_help, "Signature help")
  map("<leader>rn", function()
    require("lsp-tools").rename()
  end, "Rename with preview")
  map("<leader>gr", function()
    require("lsp-tools").lsp_references()
  end, "References")
  map("<leader>gt", function()
    require("lsp-tools").lsp_type_definitions()
  end, "Type definition")
  map("<leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
  map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
  map("<leader>wl", function()
    vim.print(vim.lsp.buf.list_workspace_folders())
  end, "List workspace folders")
end

return M
