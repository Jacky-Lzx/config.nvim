vim.treesitter.start()
-- Use regex based syntax-highlighting as fallback as VimTex needs it
local buffnr = vim.api.nvim_get_current_buf()
vim.bo[buffnr].syntax = "ON"

vim.schedule(function()
  -- NOTE: Currently TeXLab does not work correctly in terms of formatting
  vim.lsp.enable("texlab")
end)
