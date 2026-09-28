-- Use LspAttach autocommand to only map the following keys after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
    end

    map("<leader>d", vim.diagnostic.open_float, "[LSP] Show diagnostic")
    map("<leader>gk", vim.lsp.buf.signature_help, "[LSP] Signature help")
    -- vim.keymap.set("n", "<leader>sK", vim.lsp.buf.signature_help, { desc = "[LSP] Signature help" })
    map("<leader>gf", function()
      require("conform").format({ bufnr = ev.buf, lsp_format = "fallback" })
    end, "Format")
    map("<leader>rn", vim.lsp.buf.rename, "[LSP] Rename")

    map("<leader>gr", vim.lsp.buf.references, "[LSP] References")
    map("<leader>gt", vim.lsp.buf.type_definition, "[LSP] Type definition")

    map("<leader>wa", vim.lsp.buf.add_workspace_folder, "[LSP] Add workspace folder")
    map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[LSP] Remove workspace folder")
    map("<leader>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "[LSP] List workspace folders")
    -- vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts_local)
  end,
})
