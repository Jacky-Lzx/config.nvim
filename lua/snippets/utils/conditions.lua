local M = {}
M.fn = {}

M.fn.line_begin = function(line_to_cursor)
  return line_to_cursor:match("^%s*$")
end

local function has_ts_ancestor(node, type)
  if not node then
    return false
  end

  while node do
    print(node:type())
    if node:type() == type then
      return true
    end
    node = node:parent()
  end

  return false
end

M.fn.inside_node = function(node_type)
  local cursor = vim.api.nvim_win_get_cursor(0)
  cursor[1] = cursor[1] - 1
  local node_cur = vim.treesitter.get_node({ bufnr = 0, pos = cursor })

  return has_ts_ancestor(node_cur, node_type)
end

-- Create objects
local cond_obj = require("luasnip.extras.conditions")
M.obj = {}
-- traverse all key-value pairs in M.fn
for k, v in pairs(M.fn) do
  M.obj[k] = cond_obj.make_condition(v)
end

return M
