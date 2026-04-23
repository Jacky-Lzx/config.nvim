-- When a help file is opened, move its window to the right side
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("help_window_right", { clear = true }),
  pattern = { "*.txt" }, -- Help files are .txt
  callback = function()
    if vim.o.filetype == "help" then
      vim.cmd.wincmd("L")
    end
  end,
})
