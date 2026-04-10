--[
-- LuaSnip Conditions
--]

local cond_obj = require("luasnip.extras.conditions")

local M = {
  fn = {},
  obj = {},
}

local ts = vim.treesitter

local function in_math_ts()
  -- Get the node at the cursor
  local node = ts.get_node()
  if not node then
    require("snacks.notify").info("No node")
    return false
  end

  while node do
    local type = node:type()
    require("snacks.notify").info("Node type: " .. type)
    -- LaTeX specific nodes
    if type == "math_env" or type == "inline_formula" or type == "displayed_equation" or type == "math_environment" then
      require("snacks.notify").info("Detect math zone")
      return true
    end
    -- Markdown specific nodes (using tree-sitter-markdown)
    if type == "inline_math" or type == "fenced_code_block" then
      require("snacks.notify").info("Detect math zone")
      return true
    end
    node = node:parent()
  end
  require("snacks.notify").info("Not detect math zone")
  return false
end
M.fn.in_math_ts = in_math_ts

-- traverse all key-value pairs in M.fn
for k, v in pairs(M.fn) do
  M.obj[k] = cond_obj.make_condition(v)
end

return M
