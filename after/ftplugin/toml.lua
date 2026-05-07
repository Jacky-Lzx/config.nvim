vim.treesitter.start()

vim.schedule(function()
  vim.lsp.enable("taplo")
end)
