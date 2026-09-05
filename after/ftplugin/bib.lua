-- Use regex based syntax-highlighting as fallback as VimTex needs it
local bufnr = vim.api.nvim_get_current_buf()
vim.bo[bufnr].syntax = "ON"
