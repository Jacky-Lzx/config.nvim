-- Help windows do not need a gutter, including the globally reserved sign column.
vim.opt_local.statuscolumn = ""
vim.opt_local.signcolumn = "no"
vim.opt_local.foldcolumn = "0"
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "") .. " | setlocal statuscolumn< signcolumn< foldcolumn<"

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
