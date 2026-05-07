vim.treesitter.start()

vim.schedule(function()
  vim.lsp.enable("rust_analyzer")
end)
