vim.treesitter.start()

vim.schedule(function()
  vim.lsp.enable("superhtml")
end)
