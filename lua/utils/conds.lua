local M = {}

function M.is_mac()
  return vim.fn.has("mac") == 1
end

return M
