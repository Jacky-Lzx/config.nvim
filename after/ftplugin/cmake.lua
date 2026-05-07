vim.treesitter.start()

vim.schedule(function()
  vim.lsp.enable("cmake-language-server")
end)
