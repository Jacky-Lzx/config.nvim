-- This file will be loaded after the main `init.lua` and LazyVim plugins

local colors = require("catppuccin.palettes").get_palette("mocha")

vim.api.nvim_set_hl(0, "LineNr", { fg = colors.surface2 })
vim.api.nvim_set_hl(0, "Visual", { bg = colors.overlay0 })
vim.api.nvim_set_hl(0, "Search", { link = "SelectionInactive" })
vim.api.nvim_set_hl(0, "IncSearch", { bg = colors.mauve, fg = "#4b3566" })
vim.api.nvim_set_hl(0, "CurSearch", { bg = colors.mauve, fg = "#4b3566" })
vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", { bg = colors.overlay0 })
vim.api.nvim_set_hl(0, "MatchParen", { bg = colors.mauve, fg = colors.base, bold = true })

vim.api.nvim_set_hl(0, "SelectionInactive", { bg = "#4b3566" })

vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = "#2A2B3D" })
vim.api.nvim_set_hl(0, "SnacksPickerPreviewCursorLine", { bg = "#2A2B3D" })
vim.api.nvim_set_hl(0, "SnacksPickerSearch", { link = "SelectionInactive" })
vim.api.nvim_set_hl(0, "SnacksPickerMatch", { link = "SelectionInactive" })

-- minuet-ai.nvim
-- vim.api.nvim_set_hl(0, "BlinkCmpItemKindMinuet", { fg = "#a6e3a1" })

-- nvim-hlslens
vim.api.nvim_set_hl(0, "HlSearchLens", { link = "CurSearch" })
vim.api.nvim_set_hl(0, "HlSearchLensNear", { fg = "#4b3566", bg = colors.mauve, bold = true })
