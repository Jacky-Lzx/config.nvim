local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local f = ls.function_node
local d = ls.dynamic_node
local ms = ls.multi_snippet

local fmta = require("luasnip.extras.fmt").fmta
local extras = require("luasnip.extras")
local rep = extras.rep
local m = extras.match

local autosnippet = ls.extend_decorator.apply(s, { snippetType = "autosnippet" })

local conds = require("templates.snippets.tex.utils.conditions")
local cond_line_begin = require("luasnip.extras.conditions.expand").line_begin
local cond_has_selected_text = require("luasnip.extras.conditions.expand").has_selected_text

local get_visual_or_insert = function(_, parent)
  if #parent.snippet.env.SELECT_RAW == 1 then
    return sn(nil, t(vim.trim(parent.snippet.env.SELECT_RAW[1])))
  elseif #parent.snippet.env.SELECT_RAW > 1 then
    return sn(nil, t(parent.snippet.env.SELECT_RAW))
  else
    return sn(nil, i(1))
  end
end

M = {
  autosnippet(
    { trig = "mk", name = "inline_math_select", desc = "(Select) In-line math block" },
    fmta([[\(<>\)]], { d(1, get_visual_or_insert) }),
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
    fmta([[\(<>\)<>]], { i(1), i(0) }),
    {
      condition = -conds.obj.in_math,
      show_condition = conds.obj.false_fn,
    }
  ),

  autosnippet(
    { trig = "dm", name = "inline_math_select", desc = "(Select) In-line math block" },
    fmta(
      [[
        \[
          <>
        \]
      ]],
      { d(1, get_visual_or_insert) }
    ),
    {
      condition = cond_line_begin * cond_has_selected_text,
      show_condition = conds.obj.false_fn,
      priority = 2000,
    }
  ),
  autosnippet(
    { trig = "dm", name = "inline_math", desc = "In-line math block" },
    fmta(
      [[
        \[
          <>
        \]
    ]],
      { i(0) }
    ),
    {
      condition = cond_line_begin * -conds.obj.in_math,
      show_condition = conds.obj.false_fn,
    }
  ),

  autosnippet(
    { trig = "==", name = "&= align", dscr = "&= align" },
    fmta(
      [[
    &<> <> \\
    ]],
      { c(1, { t("="), t("\\leq"), i(1) }), i(2) }
    ),
    { condition = conds.fn.in_align, show_condition = conds.fn.in_align }
  ),

  s(
    {
      trig = "align",
      name = "align environment",
      dscr = "Align environment\n  Insert align in text and aligned in math environment",
    },
    fmta(
      [[
        \begin{align<>}
          <>
        \end{align<>}
      ]],
      {
        m(nil, conds.fn.in_math, "ed"),
        i(0),
        m(nil, conds.fn.in_math, "ed"),
      }
    )
  ),

  -- TODO: If not use "*", add \label automatically
  s(
    { trig = "equation", name = "equation environment", dscr = "Equation environment" },
    fmta(
      [[
        \begin{equation<>}
          <>
        \end{equation<>}
    ]],
      { c(1, { t(""), t("*") }), i(0), rep(1) }
    )
  ),

  -- fractions
  autosnippet(
    { trig = "//", name = "fraction", dscr = "Fraction" },
    fmta(
      [[
    \frac{<>}{<>}<>
    ]],
      { i(1), i(2), i(0) }
    ),
    { condition = conds.obj.in_math, show_condition = conds.obj.in_math }
  ),

  -- TODO: auto fraction
  -- autosnippet(
  --   {
  --     trig = "((\\d+)|(\\d*)(\\\\)?([A-Za-z]+)((\\^|_)(\\{\\d+\\}|\\d))*)\\/",
  --     name = "fraction",
  --     dscr = "auto fraction 1",
  --     trigEngine = "ecma",
  --   },
  --   fmta(
  --     [[
  --   \frac{<>}{<>}<>
  --   ]],
  --     { f(function(_, snip)
  --       return snip.captures[1]
  --     end), i(1), i(0) }
  --   ),
  --   { condition = cond.in_math, show_condition = cond.in_math }
  -- ),
  -- autosnippet(
  --   { trig = "(^.*\\))/", name = "fraction", dscr = "auto fraction 2", trigEngine = "ecma" },
  --   { d(1, generate_fraction) },
  --   { condition = cond.in_math, show_condition = cond.in_math }
  -- ),

  s(
    { trig = "ope", desc = "operatorname" },
    fmta([[\operatorname{<>} ]], { i(1) }),
    { show_condition = conds.obj.in_math }
  ),

  s(
    { trig = "big-bracket", desc = "Big bracket" },
    fmta(
      [[
      \left\{
        \begin{array}{ll}
          <> & <> \\
          <> & <> \\
        \end{array}
      \right.
    ]],
      { i(1), i(2), i(3), i(4) }
    ),
    { show_condition = conds.obj.in_math }
  ),

  --   "\\mathrm": {
  --   "prefix": [
  --     "mrm",
  --     "mathrm"
  --   ],
  --   "body": "\\mathrm{${1:d}} $0"
  -- },
  -- "\\mathbb": {
  --   "prefix": [
  --     "mbb",
  --     "mathbb"
  --   ],
  --   "body": "\\mathbb{$1} $0"
  -- },
  -- "\\mathcal": {
  --   "prefix": [
  --     "mcal",
  --     "mathcal"
  --   ],
  --   "body": "\\mathcal{$1} $0"
  -- },
  -- "\\mathscr": {
  --   "prefix": [
  --     "mscr",
  --     "mathscr"
  --   ],
  --   "body": "\\mathscr{$1} $0"
  -- },

  autosnippet(
    { trig = "rm", desc = "(Select) Math rm" },
    fmta(
      [[
      \mathrm{<>}
    ]],
      { d(1, get_visual_or_insert) }
    ),
    { condition = cond_has_selected_text, priority = 2000 }
  ),
  autosnippet(
    { trig = "rm", desc = "Math rm" },
    fmta(
      [[
      \mathrm{<>} <>
    ]],
      { i(1), i(0) }
    ),
    { condition = conds.obj.in_math }
  ),

  autosnippet(
    { trig = "^^", name = "superscript", desc = "Superscript", wordTrig = false },
    fmta([[^{<>}<>]], {
      i(1),
      i(0),
    }),
    { condition = conds.obj.in_math, show_condition = conds.obj.false_fn }
  ),
  autosnippet(
    { trig = "__", name = "subscript", desc = "Subscript", wordTrig = false },
    fmta([[_{<>}<>]], { i(1), i(0) }),
    { condition = conds.obj.in_math, show_condition = conds.obj.false_fn }
  ),

  s(
    { trig = "lim", name = "lim(sup|inf)", dscr = "lim(sup|inf)" },
    fmta(
      [[ 
        \lim<><><>
      ]],
      {
        c(1, { t(""), t("sup"), t("inf") }),
        c(2, { t(""), fmta([[_{<> \to <>}]], { i(1, "n"), i(2, "\\infty") }) }),
        i(0),
      }
    ),
    { condition = conds.obj.in_math, show_condition = conds.obj.in_math }
  ),

  s(
    { trig = "sum", name = "summation", dscr = "summation" },
    fmta(
      [[
        \sum<> <>
      ]],
      { c(1, { fmta([[_{<>}^{<>}]], { i(1, "i = 0"), i(2, "\\infty") }), t("") }), i(0) }
    ),
    { condition = conds.obj.in_math, show_condition = conds.obj.in_math }
  ),
}

return M
