local M = {}

function M.setup()
  require("features.lsp.diagnostics").setup()
  -- Native mapping policy belongs to LSP setup, independently of Snacks loading.
  for _, key in ipairs({ "grn", "gra", "grr", "gri" }) do
    pcall(vim.keymap.del, "n", key)
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("ConfigLsp", { clear = true }),
    callback = function(event)
      require("features.lsp.keymaps").attach(event.buf)
    end,
  })
end

return M
