local ls = require("luasnip")
local sn = ls.snippet_node
local i = ls.insert_node

local M = {}

-- FunctionNode:
-- local function fn(
--   args,     -- text from i(2) in this example i.e. { { "456" } }
--   parent,   -- parent snippet or parent node
--   user_args -- user_args from opts.user_args
-- )

M.get_insert_with_content = function(args)
  return sn(nil, i(1, M.same(args)))
end

M.get_insert_with_formulated_path_text = function(args)
  local text = args[1][1]
  -- Remove file extension
  text = text:gsub("%.[^.]*$", "")
  -- Change '_' to ' '
  text = text:gsub("_", " ")
  return sn(nil, i(1, text))
end

M.same = function(args)
  local ret = args[1][1]
  return ret
end

M.ext = function(args)
  local content = args[1][1]
  local arr = vim.split(content, ".", { plain = true })
  return arr[#arr] or content
end

M.fun_i_node = function(func)
  -- return sn(nil, i(1, func(args)))
  return function(args)
    return sn(nil, i(1, func(args)))
  end
end

return M
