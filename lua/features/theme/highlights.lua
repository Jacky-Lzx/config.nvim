local M = {}

function M.get(colors)
  return {
    LineNr = { fg = colors.surface2 },
    Visual = { bg = colors.overlay0 },
    Search = { link = "SelectionInactive" },
    CurSearch = { bg = colors.mauve, fg = "#4b3566" },
    IncSearch = { link = "CurSearch" },
    LspSignatureActiveParameter = { bg = colors.overlay0 },
    MatchParen = { bg = colors.mauve, fg = colors.base, bold = true },
    SelectionInactive = { bg = "#4b3566" },
    SnacksPickerListCursorLine = { bg = "#2A2B3D" },
    SnacksPickerPreviewCursorLine = { bg = "#2A2B3D" },
    SnacksPickerSearch = { link = "SelectionInactive" },
    SnacksPickerMatch = { link = "SelectionInactive" },
  }
end

return M
