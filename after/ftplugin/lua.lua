vim.treesitter.start()

vim.schedule(function()
  -- The LSP also colorize the colors in the code
  vim.lsp.enable("lua_ls")
end)
