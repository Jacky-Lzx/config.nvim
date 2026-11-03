local M = {}

-- The independent Mocha entry already includes these groups. Original Catppuccin
-- variants reuse the personal definitions with their own active palette.
function M.apply()
  local palette =
    vim.tbl_extend("force", require("theme_tools.mocha.palette"), require("catppuccin.palettes").get_palette())
  for name, value in pairs(require("theme_tools.mocha.groups.custom")(palette)) do
    vim.api.nvim_set_hl(0, name, value)
  end
end

return M
