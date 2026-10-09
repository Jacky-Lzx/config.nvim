local M = {}

function M.setup()
  require("features.lsp.diagnostics").setup()

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("ConfigLsp", { clear = true }),
    callback = function(event)
      require("features.lsp.keymaps").attach(event.buf)
    end,
  })
end

return M
