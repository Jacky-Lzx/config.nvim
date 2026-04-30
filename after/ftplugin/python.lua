vim.treesitter.start()

vim.schedule(function()
  -- vim.lsp.enable("pyright")
  -- vim.lsp.enable("ty")
  vim.lsp.enable("basedpyright")
end)
