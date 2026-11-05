-- Run after configuration startup with installed managed LaTeX parser/queries.
local optimize = require("utils.latex_queries").optimize
local parts = {}
for _, path in ipairs(vim.treesitter.query.get_files("latex", "highlights")) do
  parts[#parts + 1] = table.concat(vim.fn.readfile(path), "\n") .. "\n"
end
local source = table.concat(parts)
local optimized = optimize(source)
assert(optimized ~= source, "The managed upstream delimiter query changed; review the optimization")
assert(optimize(optimized) == optimized, "Optimization must be idempotent")
assert(optimize("(text) @spell") == "(text) @spell", "Unrelated queries must remain intact")
local original = vim.treesitter.query.parse("latex", source)
local candidate = vim.treesitter.query.parse("latex", optimized)

local function captures(query, text, root)
  local found = {}
  for id, node, metadata in query:iter_captures(root, text) do
    local row, col, end_row, end_col = node:range()
    local entry = {
      query.captures[id],
      row,
      col,
      end_row,
      end_col,
      metadata.priority,
      metadata.conceal,
      metadata[id],
    }
    found[#found + 1] = vim.inspect(entry)
  end
  table.sort(found)
  return found
end

local samples = {
  "$\\left( x + y \\right)$",
  "$\\left\\{ \\frac{a}{b} \\right\\}$",
  "$\\left. x \\right|$",
  "$\\left[ \\left( x \\right) \\right]$",
  "\\[ \\left\\langle x \\middle| y \\right\\rangle \\]",
  "$\\left( x$",
  "$\\left( x \\right$",
  "$\\left x \\right)$",
  "$x \\right)$",
  "$\\left( \\right)$",
  "$\\left( x \\right]$",
  "\\begin{equation}\n\\label{eq:x}\n\\left( x \\right) & = \\alpha\n\\end{equation}",
  "\\includegraphics[width=0.8\\linewidth]{./Figures/design.pdf}",
}
for i, text in ipairs(samples) do
  local tree = vim.treesitter.get_string_parser(text, "latex"):parse()[1]
  assert(
    vim.deep_equal(captures(original, text, tree:root()), captures(candidate, text, tree:root())),
    "Changed captures in sample " .. i
  )
end
print("PASS: optimized LaTeX query preserves captures and metadata across valid and incomplete formulas")
