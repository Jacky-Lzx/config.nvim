local M = {}

function M.attach(buffer)
  local bindings = require("config.bindings")
  if bindings.entries["config.lsp." .. buffer] then
    return
  end
  local entries = {}
  local function map(id, key, action, description)
    entries[#entries + 1] = { key, action, id = "lsp." .. id, desc = "[LSP] " .. description }
  end

  map("line_diagnostics", "<leader>d", function()
    vim.diagnostic.open_float({ scope = "line", focus = true })
  end, "Show line diagnostics")
  map("signature", "<leader>gk", vim.lsp.buf.signature_help, "Signature help")
  map("signature_alias", "gK", vim.lsp.buf.signature_help, "Signature help")
  map("rename", "<leader>rn", function()
    require("lsp-tools").rename()
  end, "Rename with preview")
  map("references", "<leader>gr", function()
    require("lsp-tools").lsp_references()
  end, "References")
  map("type_definition", "<leader>gt", function()
    require("lsp-tools").lsp_type_definitions()
  end, "Type definition")
  map("workspace_add", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
  map("workspace_remove", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
  map("workspace_list", "<leader>wl", function()
    vim.print(vim.lsp.buf.list_workspace_folders())
  end, "List workspace folders")
  bindings.set_buffer("config.lsp", buffer, entries)
end

return M
