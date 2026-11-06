local M = {}
local prepared = false

local delimiter = [[(math_delimiter
  left_command: _ @punctuation.delimiter
  left_delimiter: _ @punctuation.delimiter
  right_command: _ @punctuation.delimiter
  right_delimiter: _ @punctuation.delimiter)]]

-- These fields are present together on math_delimiter nodes. Independent
-- patterns avoid the expensive four-capture combination during TSQuery compile.
-- Match the known upstream rule exactly; a changed rule keeps its own semantics.
function M.optimize(text)
  local first, last = text:find(delimiter, 1, true)
  if not first then
    return text
  end
  local patterns = {}
  for _, field in ipairs({ "left_command", "left_delimiter", "right_command", "right_delimiter" }) do
    patterns[#patterns + 1] = "(math_delimiter\n  " .. field .. ": _ @punctuation.delimiter)"
  end
  return text:sub(1, first - 1) .. table.concat(patterns, "\n\n") .. text:sub(last + 1)
end

function M.prepare()
  if prepared then
    return
  end
  prepared = true
  local query = vim.treesitter.query
  local parts = {}
  -- get_files includes inherited queries and runtime extensions in their normal
  -- order, including this configuration's math background and brace priorities.
  for _, path in ipairs(query.get_files("latex", "highlights")) do
    parts[#parts + 1] = table.concat(vim.fn.readfile(path), "\n") .. "\n"
  end
  local text = table.concat(parts)
  local optimized = M.optimize(text)
  if optimized ~= text then
    query.set("latex", "highlights", optimized)
  end
end

return M
