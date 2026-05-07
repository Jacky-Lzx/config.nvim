vim.treesitter.start()

-- Set the markdown style with the tabindent values set in the config instead of the built-in value
vim.g.markdown_recommended_style = 0

vim.schedule(function()
  -- FIXME: Vale is not configured correctly. It doesn't work
  -- vim.lsp.enable("vale_ls")

  -- To enable project-wide features of marksman (cross-file references and completions), either
  --  - Have a git repository
  --  - Have a `.markdman.toml` file in the project root

  -- marksman does not support configure its settings through lsp.
  -- You can only configure it in `.marksman.toml`
  -- For available configurations, see `https://github.com/artempyanykh/marksman/blob/main/Tests/default.marksman.toml`
  vim.lsp.enable("marksman")

  vim.lsp.enable("harper_ls")
end)
