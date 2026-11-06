-- Verify that production uses immutable queries from the same fork as the parser.
local source = require("languages.latex.plugins")[1].opts.parsers.sources.latex
local info = require("toolchain.parsers").info("latex")
assert(info.intact and info.current == info.session, "Restart after installing the pinned LaTeX parser")
assert(info.receipt.parser.revision == source.parser.revision, "Wrong LaTeX parser revision")
assert(info.receipt.parser.url == source.parser.url, "Wrong LaTeX parser fork")
assert(info.receipt.parser.queries == "neovim/queries/latex")
assert(vim.deep_equal(info.receipt.query_source, source.query_source), "Queries must come from the parser fork")
local files = vim.treesitter.query.get_files("latex", "highlights")
assert(vim.deep_equal(files, { info.session .. "/queries/latex/highlights.scm" }), vim.inspect(files))
assert(not package.loaded["languages.latex.queries"], "Runtime query rewriting must be removed")

local query = assert(vim.treesitter.query.get("latex", "highlights"))
local text = "$\\left( x + \\alpha \\right)$"
local tree = vim.treesitter.get_string_parser(text, "latex"):parse()[1]
local delimiter_count, math = 0, false
for id, _, metadata in query:iter_captures(tree:root(), text) do
  if query.captures[id] == "punctuation.delimiter" then
    delimiter_count = delimiter_count + 1
    assert((tonumber(metadata.priority) or 100) == 100)
  elseif query.captures[id] == "markup.math" then
    assert(tonumber(metadata.priority) == 90)
    math = true
  end
end
assert(delimiter_count == 4 and math, "Fork delimiter captures and math priorities are missing")
print("PASS: LaTeX parser and unpatched queries use the same pinned fork revision")
