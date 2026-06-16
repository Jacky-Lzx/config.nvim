vim.treesitter.start()

vim.opt_local.makeprg = "python3 %"

vim.schedule(function()
  -- vim.lsp.enable("pyright")
  -- vim.lsp.enable("ty")
  vim.lsp.enable("basedpyright")
end)
