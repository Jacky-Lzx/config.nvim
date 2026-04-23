-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.clipboard = ""

vim.cmd([[ autocmd FileType * set formatoptions-=ro ]])

require("vscode_setting.plugins_vscode")
