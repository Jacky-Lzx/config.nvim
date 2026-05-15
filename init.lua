vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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

vim.wo.cursorline = false

vim.opt.clipboard = ""

vim.o.textwidth = 120
-- Prevent auto insertion of new lines when writing a long sentence
vim.api.nvim_create_autocmd("FileType", {
  callback = function(_)
    vim.opt.formatoptions = { q = true, j = true, n = true }
  end,
})

-- Set block cursor with blinking in all modes
-- vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"
--   .. ",a:blinkwait700-blinkoff500-blinkon500-Cursor/lCursor"
--   .. ",sm:block-blinkwait175-blinkoff150-blinkon175"

-- Enables project-local `.nvim.lua` configuration file
vim.o.exrc = true

vim.opt.shell = "fish"

local python_path = ""
local uname = vim.uv.os_uname()
if uname.sysname == "Linux" then
  python_path = "/home/lzx/.pyenv/versions/3.10.0/envs/neovim3/bin/python3"
elseif uname.sysname == "Darwin" then
  python_path = vim.fn.expand("$HOME/.uv/neovim/bin/python3")
  -- elseif uname.sysname == "Windows_NT" then
end

vim.g.python3_host_prog = python_path

if vim.g.neovide then
  require("neovide.neovide")
end

require("plugin")
