--- Many of the autocommands are adapted from LazyVim (https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua)

local function augroup(name)
  return vim.api.nvim_create_augroup("lzx_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})
