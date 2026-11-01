local M = {}
function M.apply()
  local colors = require("catppuccin.palettes").get_palette("mocha")

  vim.api.nvim_set_hl(0, "LineNr", { fg = colors.surface2 })
  vim.api.nvim_set_hl(0, "Visual", { bg = colors.overlay0 })
  vim.api.nvim_set_hl(0, "Search", { link = "SelectionInactive" })
  vim.api.nvim_set_hl(0, "CurSearch", { bg = colors.mauve, fg = "#4b3566" })
  vim.api.nvim_set_hl(0, "IncSearch", { link = "CurSearch" })
  vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", { bg = colors.overlay0 })
  vim.api.nvim_set_hl(0, "MatchParen", { bg = colors.mauve, fg = colors.base, bold = true })

  vim.api.nvim_set_hl(0, "SelectionInactive", { bg = "#604482" })

  vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = "#45475a" })
  vim.api.nvim_set_hl(0, "SnacksPickerPreviewCursorLine", { link = "SnacksPickerListCursorLine" })
  vim.api.nvim_set_hl(0, "SnacksPickerSearch", { link = "SelectionInactive" })
  vim.api.nvim_set_hl(0, "SnacksPickerMatch", { link = "SelectionInactive" })

  -- ui-tools owns editor decorations; keep the existing Catppuccin palette.
  vim.api.nvim_set_hl(0, "UiToolsIndent", { fg = colors.surface1 })
  vim.api.nvim_set_hl(0, "UiToolsScope", { fg = colors.flamingo })
  vim.api.nvim_set_hl(0, "UiToolsGuide", { link = "NonText" })
  vim.api.nvim_set_hl(0, "UiToolsFlash", { link = "Visual" })
  vim.api.nvim_set_hl(0, "UiToolsDim", { fg = colors.overlay0 })
  vim.api.nvim_set_hl(0, "UiToolsBackdrop", { bg = colors.base, fg = colors.base })
  vim.api.nvim_set_hl(0, "UiToolsScrollbar", { bg = "NONE", blend = 100 })
  vim.api.nvim_set_hl(0, "UiToolsScrollbarHandle", { bg = "#000000", blend = 0 })
  vim.api.nvim_set_hl(0, "UiToolsScrollbarCursor", { fg = colors.peach })
  vim.api.nvim_set_hl(0, "UiToolsSearch", { fg = colors.mauve })

  -- minuet-ai.nvim
  -- vim.api.nvim_set_hl(0, "BlinkCmpItemKindMinuet", { fg = "#a6e3a1" })

  -- nvim-hlslens
  vim.api.nvim_set_hl(0, "HlSearchLens", { link = "CurSearch" })
  vim.api.nvim_set_hl(0, "HlSearchLensNear", { fg = "#4b3566", bg = colors.mauve, bold = true })
end
return M
