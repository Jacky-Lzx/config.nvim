-- Run from the config root with:
-- nvim --headless -u NONE -i NONE --noplugin -l tests/math_conditions.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
package.preload["luasnip.extras.conditions"] = function()
  return {
    make_condition = function(fn)
      return fn
    end,
  }
end

local ts = vim.treesitter
local parser_mode, query_mode = "throw", "throw"
local scans, parses, queries = 0, 0, 0
local captures = {}
local function node(text, range, parent)
  return {
    range = function()
      return unpack(range or { 0, 0, 0, 3 })
    end,
    parent = function()
      return parent
    end,
    text = text,
  }
end
local parser = {
  parse = function()
    parses = parses + 1
    if parser_mode == "parse_error" then
      error("parse failed")
    end
    if parser_mode == "empty" then
      return {}
    end
    return { {
      root = function()
        return {}
      end,
    } }
  end,
}
ts.get_parser = function()
  if parser_mode == "throw" then
    error("parser unavailable")
  end
  if parser_mode == "nil" then
    return nil
  end
  return parser
end
ts.get_node = function()
  error("node unavailable")
end
ts.get_node_text = function(n)
  return n.text
end
ts.query.parse = function(_, source)
  queries = queries + 1
  if query_mode == "throw" then
    error("query unavailable")
  end
  local document = source:find("class_include", 1, true)
  return {
    captures = document and { "document_type" } or { "inline", "env_name" },
    iter_captures = function()
      scans = scans + 1
      local i = 0
      return function()
        i = i + 1
        if captures[i] then
          return captures[i][1], captures[i][2]
        end
      end
    end,
  }
end

local checks = 0
local function eq(actual, expected, label)
  checks = checks + 1
  assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function buffer(lines, ft, row, col)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo.filetype = ft or "tex"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { row or 1, col or 1 })
  return buf
end
local function edit(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

buffer({ "$x$" }, "markdown")
local M = require("snippets.tex.utils.math_conditions")
eq(queries, 0, "loading Markdown does not compile LaTeX queries")
eq(M.fn.true_fn(), true, "true condition")
eq(M.obj.false_fn(), false, "wrapped false condition")
for _, enabled in ipairs({ false, true }) do
  M.setup({ use_cache = enabled })
  for _, mode in ipairs({ "throw", "nil", "parse_error", "empty" }) do
    parser_mode = mode
    buffer({ "$x$" }, "markdown")
    eq(M.is_mathzone(), true, "parser failure fallback " .. mode)
  end
  parser_mode = "ok"
  buffer({ "$x$" })
  eq(M.is_mathzone(), true, "query failure fallback")
  eq(M.fn.in_beamer(), false, "document query failure")
  parser_mode = "throw"
  for _, case in ipairs({
    { "tikzpicture", "in_tikz" },
    { "align", "in_align" },
    { "figure", "in_figure" },
    { "itemize", "in_bullets" },
  }) do
    buffer({ "\\begin{" .. case[1] .. "}", "content", "\\end{" .. case[1] .. "}" }, "tex", 2)
    eq(M.fn[case[2]](), true, "environment fallback " .. case[1])
    edit({ "plain", "content", "plain" })
    eq(M.fn[case[2]](), false, "environment edit invalidation")
  end
  buffer({ "$a + \\text{words} + b$" }, "tex", 1, 12)
  eq(M.fn.math_mode(), false, "text exclusion")
  eq(M.fn.math_mode(), false, "repeated text exclusion")
  edit({ "$a + \\text{a {nested} word} + b$" })
  vim.api.nvim_win_set_cursor(0, { 1, 22 })
  eq(M.fn.math_mode(), false, "nested text group")
  buffer({ "\\(x\\) " }, "tex", 1, 2)
  eq(M.is_mathzone_fallback(), true, "LaTeX inline fallback")
  buffer({ "\\[x\\] " }, "tex", 1, 2)
  eq(M.is_mathzone_fallback(), true, "LaTeX display fallback")
  vim.api.nvim_win_set_cursor(0, { 1, 5 })
  eq(M.is_mathzone_fallback(), false, "exclusive fallback end")
  buffer({ "\\begin[mode=display]{math}", "content", "\\end{math}" }, "sile", 2)
  eq(M.is_in_sile_display_math(), true, "SILE detection")
  edit({ "plain", "content", "plain" })
  eq(M.is_in_sile_display_math(), false, "SILE invalidation")
end

M.setup({ use_cache = true, cache_size = 20 })
buffer({ "$x$" })
eq(M.is_mathzone_fallback(), true, "fallback cached true")
buffer({ "abc" })
eq(M.is_mathzone_fallback(), false, "buffer isolation")
edit({ "$x$" })
eq(M.is_mathzone_fallback(), true, "changedtick isolation")
edit({ "abc" })
eq(M.is_mathzone_fallback(), false, "changedtick negative")
local misses = 0
M.cache.config.on_miss = function()
  misses = misses + 1
end
M.cache:set("test", "false", false)
eq(M.cache:get("test", "false"), false, "false cache hit")
eq(misses, 0, "false does not call on_miss")

M.setup({ cache_size = 2, eviction_strategy = "arc" })
M.cache:set("test", "a", false)
M.cache:set("test", "b", true)
M.cache:set("test", "b", false)
eq(M.cache:size(), 2, "updating full cache does not evict")
M.cache:get("test", "a")
M.cache:set("test", "c", true)
eq(M.cache:get("test", "b"), nil, "arc evicts least recent")
eq(M.cache:get("test", "a"), false, "arc retains recently used false")
M.setup({ cache_size = 0 })
M.cache:set("test", "a", true)
eq(M.cache:size(), 0, "zero capacity")

M.setup({ cache_size = 50 })
parser_mode, query_mode = "ok", "ok"
captures = { { 1, node(nil, { 0, 0, 0, 3 }) } }
buffer({ "$x$ plain" })
local before = scans
local parses_before = parses
eq(M.is_mathzone(), true, "tree math range")
vim.api.nvim_win_set_cursor(0, { 1, 4 })
eq(M.is_mathzone(), false, "tree outside range")
eq(M.is_mathzone(), false, "tree negative cached")
eq(scans, before + 1, "one tree scan across cursor movement")
eq(parses, parses_before + 1, "one parse across cursor movement")
edit({ "plain" })
captures = {}
eq(M.is_mathzone(), false, "tree invalidation")
eq(scans, before + 2, "edit rescans tree")
vim.bo.filetype = "markdown"
eq(M.is_mathzone(), false, "filetype isolation")
eq(scans, before + 3, "filetype change rescans")

local env = node(nil, { 0, 0, 2, 12 })
captures = { { 2, node("equation", nil, node(nil, nil, node(nil, nil, env))) } }
buffer({ "\\begin{equation}", "x", "\\end{equation}" }, "tex", 2, 0)
eq(M.is_mathzone(), true, "environment range includes body")
M.setup({ math_environments = { latex = { equation = false } } })
eq(M.is_mathzone(), false, "setup invalidates configured environment ranges")
M.setup({ math_environments = { latex = { equation = true } } })

captures = { { 1, node(nil, { 0, 0, 0, 50 }) } }
buffer({ "$a + \\text{words} + b$" }, "tex", 1, 12)
eq(M.is_mathzone(), true, "tree math inside text command")
eq(M.fn.math_mode(), false, "cached tree true must not bypass text exclusion")
eq(M.fn.math_mode(), false, "cached text exclusion")
edit({ "$a + words + b$" })
eq(M.fn.math_mode(), true, "text edit invalidation")
buffer({ "$a + \\text{words} + b$" }, "tex", 1, 12)
eq(M.fn.math_mode(), false, "text buffer isolation")
vim.bo.filetype = "markdown"
eq(M.fn.math_mode(), true, "text filetype isolation")

captures = {}
buffer({ "plain" }, "tex", 1, 1)
eq(M.is_mathzone(), false, "tree buffer isolation")
M.setup({ use_cache = false })
before = scans
eq(M.is_mathzone(), false, "uncached tree negative")
eq(M.is_mathzone(), false, "repeated uncached tree negative")
eq(scans, before + 2, "disabled cache is honored")
M.setup({ use_cache = true })

parser_mode = "parse_error"
M.setup({ incremental_parsing = { enabled = false, max_lines_for_full_parse = 0 } })
buffer({ "$x$" })
eq(M.is_mathzone(), true, "forced parse failure fallback")
M.setup({ incremental_parsing = { enabled = true } })
parser_mode = "ok"
buffer({ "\\begin{figure}", "content", "\\end{figure}" }, "tex", 2)
eq(M.fn.in_figure(), true, "get_node failure fallback")

captures = { { 1, node("beamer") } }
buffer({ "\\documentclass{beamer}", "text" })
before = scans
eq(M.fn.in_beamer(), true, "document type")
vim.api.nvim_win_set_cursor(0, { 2, 1 })
eq(M.fn.in_beamer(), true, "document type across cursor movement")
eq(scans, before + 1, "document scanned once")
captures = {}
edit({ "plain", "text" })
eq(M.fn.in_beamer(), false, "document invalidation")
eq(M.fn.in_beamer(), false, "negative document cached")
eq(scans, before + 2, "negative document scanned once")
parser_mode = "throw"
buffer({ "\\documentclass{beamer}" })
eq(M.fn.in_beamer(), false, "missing document parser")

local context_calls = 0
local context_result, context_error = true, nil
package.loaded["tex-tools"] = {
  in_math = function()
    context_calls = context_calls + 1
    return context_result, context_error
  end,
}
buffer({ "$x$" }, "tex")
eq(M.fn.math_mode(), true, "TeX uses structural context")
context_result = false
eq(M.fn.math_mode(), false, "negative structural context does not use regex fallback")
buffer({ "$x$" }, "plaintex")
eq(M.fn.math_mode(), false, "plaintex uses structural context")
context_error = "parser unavailable"
eq(M.fn.math_mode(), true, "unavailable structural parser keeps fallback")
local context_before = context_calls
buffer({ "$x$" }, "markdown")
eq(M.fn.math_mode(), true, "Markdown keeps its own math detection")
eq(context_calls, context_before, "Markdown never asks for a LaTeX tree")
package.loaded["tex-tools"] = nil

local called = false
M.fn.math_mode = function()
  called = true
  return true
end
vim.cmd("CheckCursorMathZone")
eq(called, true, "command uses M.fn.math_mode")
print(string.format("math_conditions: %d checks passed", checks))
