local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node

local fmta = require("luasnip.extras.fmt").fmta

local autosnippet = ls.extend_decorator.apply(s, { snippetType = "autosnippet" })

local utils = require("templates.snippets.utils.utils")
local conds = require("templates.snippets.tex.utils.conditions")
local cond_line_begin = require("luasnip.extras.conditions.expand").line_begin
local cond_has_selected_text = require("luasnip.extras.conditions.expand").has_selected_text

-- Copied from latex snippets
local get_visual_or_insert = function(_, parent)
  if #parent.snippet.env.SELECT_RAW == 1 then
    return sn(nil, t(vim.trim(parent.snippet.env.SELECT_RAW[1])))
  elseif #parent.snippet.env.SELECT_RAW > 1 then
    return sn(nil, t(parent.snippet.env.SELECT_RAW))
  else
    return sn(nil, i(1))
  end
end

local function generate_table(_, snip)
  local rows = tonumber(snip.captures[1])
  local cols = tonumber(snip.captures[2])
  local table = {}

  local insert_index = 0

  -- first line
  table[#table + 1] = t("| ")
  for c = 1, cols do
    insert_index = insert_index + 1
    table[#table + 1] = i(insert_index, tostring(insert_index))
    if c < cols then
      table[#table + 1] = t(" | ")
    end
  end
  table[#table + 1] = t({ " |", "" })

  -- table line
  table[#table + 1] = t("| ")
  for c = 1, cols do
    table[#table + 1] = t("-")
    if c < cols then
      table[#table + 1] = t(" | ")
    end
  end
  table[#table + 1] = t({ " |", "" })

  for _ = 3, rows + 1 do
    -- local row = {}
    table[#table + 1] = t("| ")
    for c = 1, cols do
      insert_index = insert_index + 1
      table[#table + 1] = i(insert_index, tostring(insert_index))
      if c < cols then
        table[#table + 1] = t(" | ")
      end
    end
    table[#table + 1] = t({ " |", "" })
  end

  return sn(nil, table)
end

local function generate_list(_, snip, _, user_arg)
  local num = tonumber(snip.captures[1])
  local table = {}
  for index = 1, num do
    if user_arg == "1" then
      table[#table + 1] = t(tostring(index) .. ". ")
    else
      table[#table + 1] = t("- ")
    end

    table[#table + 1] = i(index, tostring(index))

    if index ~= num then
      table[#table + 1] = t({ "", "" })
    end
  end

  return sn(nil, table)
end

local function repeat_hash(_, snip)
  local n = tonumber(snip.captures[1])
  if n and n > 0 then
    return sn(nil, { t(string.rep("#", n)), t(" "), i(1) })
  else
    return sn(nil, { t("# "), i(1) })
  end
end

return {
  -- stylua: ignore
  s({ trig = "figure", desc = "Image" }, {
    t("!["),
    -- i(0, "content"),
    d(2, utils.get_insert_with_formulated_path_text, {1}),
    t({ "](./Figures_markdown/" }),
    i(1),
    t(")"),
    i(0)
  }),

  -- stylua: ignore
  autosnippet(
    { trig = "#(%d+)%s", desc = "Repeat # n times", regTrig = true, hidden = true },
    { d(1, repeat_hash, {}) },
    { condition = cond_line_begin }
  ),

  -- stylua: ignore
  autosnippet({trig = "table(%d+)x(%d+)%s", desc = "Table generation", regTrig = true, hidden = true},
    {d(1, generate_table, {})}, {condition = cond_line_begin}
  ),


  -- stylua: ignore
  autosnippet({trig = "item(%d+)%s", desc = "Itemize generation", regTrig = true, hidden = true},
    {d(1, generate_list, {}, {user_args = {"-"}})}, {condition = cond_line_begin}
  ),

  -- stylua: ignore
  autosnippet(
    {trig = "enum(%d+)%s", desc = "Enumerate generation", regTrig = true, hidden = true},
    {d(1, generate_list, {}, {user_args = {"1"}})}, {condition = cond_line_begin}
  ),

  -- Copied and modified from latex snippets
  autosnippet(
    { trig = "mk", name = "inline_math_select", desc = "(Select) In-line math block" },
    fmta([[$<>$]], { d(1, get_visual_or_insert) }),
    {
      condition = cond_has_selected_text,
      show_condition = conds.obj.false_fn,
      priority = 2000,
    }
  ),
  autosnippet(
    {
      trig = "mk",
      name = "inline_math",
      desc = "In-line math block",
    },
    fmta([[$<>$<>]], { i(1), i(0) }),
    {
      show_condition = conds.obj.false_fn,
    }
  ),
}
