local M = {}

function M.ends_with(str, suffix)
  return str:sub(-#suffix) == suffix
end

return M
