local utils = require("templates.snippets.utils.utils")
local math_conds = require("templates.snippets.tex.utils.math_conditions")
local cond_line_begin = require("luasnip.extras.conditions.expand").line_begin
local cond_has_selected_text = require("luasnip.extras.conditions.expand").has_selected_text
local nodes_util = require("templates.snippets.utils.nodes")

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

return
-- Normal snippets
{
  s({ trig = "figure", desc = "Image" }, {
    t("!["),
    -- i(0, "content"),
    d(2, utils.get_insert_with_formulated_path_text, { 1 }),
    t({ "](./Figures_markdown/" }),
    i(1),
    t(")"),
    i(0),
  }),

  s(
    { trig = "link", desc = "Link" },
    fmta([[[<>](<>)]], {
      i(1, "NAME"),
      d(2, nodes_util.visual_or_insert, {}, { user_args = { true, "LINK" } }),
    })
  ),

  s(
    { trig = "code", desc = "Code block" },
    fmta(
      [[
        ```<>
        <>
        ```
      ]],
      {
        i(1),
        d(2, nodes_util.visual_or_insert),
      }
    )
  ),

  -- Bold Text
  s("bold", { t("**"), d(1, nodes_util.visual_or_insert, {}, { user_args = { true, "BOLD" } }), t("**") }),

  -- Italics
  s("italic", { t("_"), d(1, nodes_util.visual_or_insert, {}, { user_args = { true, "ITALIC" } }), t("_") }),

  -- Strikethrough
  s("strike", { t("~~"), d(1, nodes_util.visual_or_insert, {}, { user_args = { true, "STRIKETHROUGH" } }), t("~~") }),

  -- Blockquote
  s("quote", { t("> "), d(1, nodes_util.visual_or_insert, {}, { user_args = { true, "QUOTE" } }) }),

  -- Emphasis Variations
  s(
    { trig = "emph", desc = "Emphasis", priority = 2000 }, -- Higher priority to avoid conflict with "emph" snippet from LaTeX
    { t("**_"), d(1, nodes_util.visual_or_insert, {}, { user_args = { true, "EMPH" } }), t("_**") }
  ),

  -- HTML Comment
  s("comment", { t("<!-- "), d(1, nodes_util.visual_or_insert, {}, { user_args = { true, "COMMENT" } }), t(" -->") }),

  -- Task List
  s(
    { trig = "todo", desc = "Checkbox", priority = 2000 }, -- Higher priority to avoid conflict with the todo-comment snippets
    fmta([[- <> ]], { c(1, { { t("["), i(1, " "), t("]") }, t("[x]") }) })
  ),
},
-- Autosnippets
{
  -- Headers: e.g. "#3 " will be expanded to "### " with the cursor after the space
  s(
    { trig = "#(%d+)%s", desc = "Repeat # n times", regTrig = true, hidden = true },
    { d(1, repeat_hash, {}) },
    { condition = cond_line_begin }
  ),

  s(
    { trig = "table(%d+)x(%d+)%s", desc = "Table generation", regTrig = true, hidden = true },
    { d(1, generate_table, {}) },
    { condition = cond_line_begin }
  ),

  s(
    { trig = "item(%d+)%s", desc = "Itemize generation", regTrig = true, hidden = true },
    { d(1, generate_list, {}, { user_args = { "-" } }) },
    { condition = cond_line_begin }
  ),

  s(
    { trig = "enum(%d+)%s", desc = "Enumerate generation", regTrig = true, hidden = true },
    { d(1, generate_list, {}, { user_args = { "1" } }) },
    { condition = cond_line_begin }
  ),

  -- Copied and modified from latex snippets
  s(
    { trig = "mk", name = "math_inline", desc = "Math (inline)" },
    fmta([[$<>$]], { d(1, nodes_util.visual_or_insert) }),
    {
      condition = cond_has_selected_text + -math_conds.obj.in_math,
      show_condition = math_conds.obj.false_fn,
    }
  ),
  s(
    { trig = "dm", name = "math_block", desc = "Math (block)" },
    fmta(
      [[
        $$
          <>
        $$
    ]],
      { d(1, nodes_util.visual_or_insert) }
    ),
    {
      -- `dm` snippet does not need to be at the start of a line
      condition = (cond_line_begin * cond_has_selected_text) + -math_conds.obj.in_math,
      show_condition = math_conds.obj.false_fn,
    }
  ),
}
