-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

-- vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 10
vim.opt.startofline = false

vim.opt.list = true
vim.opt.listchars = { tab = ">-" }

vim.o.signcolumn = "yes:1"

-- vim.opt_local.conceallevel = 2
vim.opt.conceallevel = 2

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.wo.wrap = false

vim.o.winborder = "rounded"

-- vim.bo.tabstop = 2

vim.wo.cursorline = true

vim.opt.clipboard = ""

vim.o.textwidth = 120
-- Prevent auto insertion of new lines when writing a long sentence
vim.api.nvim_create_autocmd("FileType", {
  command = "set formatoptions-=cro",
})

-- Enables project-local `.nvim.lua` configuration file
vim.o.exrc = true

vim.opt.shell = "fish"

local python_path = ""
local uname = vim.uv.os_uname()
if uname.sysname == "Linux" then
  python_path = "/home/lzx/.pyenv/versions/3.10.0/envs/neovim3/bin/python3"
elseif uname.sysname == "Darwin" then
  python_path = "/opt/homebrew/anaconda3/envs/neovim/bin/python3"
  -- elseif uname.sysname == "Windows_NT" then
end

vim.g.python3_host_prog = python_path

-- vim.opt.formatoptions:remove { "r", "o" }
vim.cmd([[ autocmd FileType * set formatoptions-=ro ]])

-- When a help file is opened, move its window to the right side
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    -- Equivalent to :wincmd L in Vimscript
    vim.cmd("wincmd L")
  end,
})

require("global")

if vim.g.neovide then
  require("neovide.neovide")
end

require("plugin")

require("keymapping")

-- Snacks profiler settings
-- Use `PROF=1` nvim to start profiling
if vim.env.PROF then
  -- example for lazy.nvim
  -- change this to the correct path for your plugin manager
  local snacks = vim.fn.stdpath("data") .. "/lazy/snacks.nvim"
  vim.opt.rtp:append(snacks)
  ---@diagnostic disable-next-line: missing-fields
  require("snacks.profiler").startup({
    startup = {
      event = "VimEnter", -- stop profiler on this event. Defaults to `VimEnter`
      -- event = "UIEnter",
      -- event = "VeryLazy",
    },
  })
end
