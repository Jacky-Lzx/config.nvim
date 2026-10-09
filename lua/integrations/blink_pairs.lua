local M = {}

-- Blink accepts completion first, then delegates newline handling to pairs.nvim.
function M.newline()
  return require("pairs").expr("<CR>")
end

return M
