local M = {}

-- Locate resources in this checkout, including -u /path/to/init.lua startup.
local source = debug.getinfo(1, "S").source:sub(2)
M.root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))

function M.config(...)
  return vim.fs.joinpath(M.root, ...)
end

return M
