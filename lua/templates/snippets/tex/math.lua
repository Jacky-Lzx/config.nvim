local math_conds = require("templates.snippets.tex.utils.math_conditions")
local cond_line_begin = require("luasnip.extras.conditions.expand").line_begin
local cond_has_selected_text = require("luasnip.extras.conditions.expand").has_selected_text
local nodes_util = require("templates.snippets.utils.nodes")

local str_util = require("templates.snippets.utils.strings")

local M = {}

local function symbol(prefix, desc, body)
  return s(
    { trig = prefix, desc = desc },
    fmta(body, {}),
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  )
end
local function symbol_mult(prefix_mult, desc, body)
  local conditions = {}
  for _, prefix in ipairs(prefix_mult) do
    table.insert(
      conditions,
      { trig = prefix, desc = desc, condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
    )
  end
  return ms(conditions, fmta(body, {}))
end
local function big_bracket(prefix, desc, left, right)
  return s(
    { trig = prefix, desc = desc },
    fmta([[\left<> <> \right<>]], { t(left), i(1), t(right) }),
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  )
end

M.snippets = {
  s(
    {
      trig = "align",
      name = "align_environment",
      desc = "Align environment\n  Insert align in text and aligned in math environment",
    },
    fmta(
      [[
        \begin{<>}
          <>
        \end{<>}
      ]],
      {
        sn(1, { m(nil, math_conds.fn.in_math, "aligned", "align") }),
        i(0),
        rep(1),
      }
    )
  ),

  s(
    { trig = "equation", name = "equation environment", desc = "Equation environment" },
    fmta(
      [[
        \begin{equation<>}
          <>
        \end{equation<>}
    ]],
      {
        c(1, {
          t(""),
          t("*"),
        }),
        d(2, function(args)
          -- args = { { "" } } or { { "*" } }
          if str_util.ends_with(args[1][1], "*") then
            return sn(nil, { i(1) })
          else
            return sn(nil, { i(1), t({ "", "  \\label{eq:" }), i(2), t("}") })
          end
        end, { 1 }),
        rep(1),
      }
    ),
    { show_condition = -math_conds.obj.in_math }
  ),

  s(
    { trig = "ope", desc = "operatorname" },
    fmta([[\operatorname{<>}]], { d(1, nodes_util.visual_or_insert) }),
    { show_condition = math_conds.obj.in_math }
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
    { show_condition = math_conds.obj.in_math }
  ),

  s(
    { trig = "lim", name = "lim(sup|inf)", desc = "Lim(sup|inf)" },
    fmta([[\lim<><>]], {
      c(1, { t(""), t("sup"), t("inf") }),
      c(2, { t(""), fmta([[_{<> \to <>}]], { i(1, "n"), i(2, "\\infty") }) }),
    }),
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),

  s(
    { trig = "sum", name = "summation", desc = "Summation" },
    fmta([[\sum<>]], { c(1, { fmta([[_{<>}^{<>}]], { i(1, "i = 0"), i(2, "\\infty") }), t("") }) }),
    { show_condition = math_conds.obj.in_math }
  ),
  s(
    { trig = "int", name = "integral", desc = "Integral" },
    fmta([[\int<>]], { c(1, { fmta([[_{<>}^{<>}]], { i(1, "i = 0"), i(2, "\\infty") }), t("") }) }),
    { show_condition = math_conds.obj.in_math }
  ),

  s(
    { trig = "color", name = "color", desc = "Text color" },
    fmta([[\textcolor<>{<>}]], {
      c(1, {
        -- fmta does not work well with nested choices
        sn(nil, { t("{"), i(1, "green"), t("}") }),
        sn(nil, { t("[RGB]{"), i(1, "0"), t(","), i(2, "255"), t(","), i(3, "0"), t("}") }),
      }),
      d(2, nodes_util.visual_or_insert),
    }),
    { show_condition = -math_conds.obj.in_math }
  ),

  s(
    { trig = "box", desc = { "Box around equation", "\tNeed `\\usepackage{fbox}`" } },
    fmta([[\boxed{<>}]], { d(1, nodes_util.visual_or_insert) }),
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),

  s(
    { trig = "array", name = "array", desc = "Array" },
    nodes_util.fmt_env("array", sn(1, { t("{"), i(1, "ll"), t("}") })),
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),

  s(
    { trig = "text", name = "text", desc = "`\\text{}`" },
    fmta([[\text{<>}]], { d(1, nodes_util.visual_or_insert) }),
    { show_condition = math_conds.obj.in_math }
  ),

  s(
    { trig = "matrix", name = "matrix", desc = { "Matrix", "\tThe matrix without close characters" } },
    nodes_util.fmt_env("matrix"),
    { show_condition = math_conds.obj.in_math }
  ),
  s(
    { trig = "matrix[]", name = "bmatrix", desc = { "bmatrix", "\tThe matrix with '[]' characters" } },
    nodes_util.fmt_env("bmatrix"),
    { show_condition = math_conds.obj.in_math }
  ),
  s(
    { trig = "matrix()", name = "pmatrix", desc = { "pmatrix", "\tThe matrix with '()' characters" } },
    nodes_util.fmt_env("pmatrix"),
    { show_condition = math_conds.obj.in_math }
  ),

  symbol("=>", "Short implies", [[\Rightarrow]]),
  symbol("==>", "Implies", [[\implies]]),
  symbol("<=>", "Equivalence", [[\Leftrightarrow]]),
  symbol("<==>", "Long equivalence", [[\iff]]),
  symbol("and", "Logic AND", [[\land]]),
  symbol("or", "Logic OR", [[\lor]]),
  symbol("not", "Logic NOT", [[\lnot]]),
  symbol("xor", "Logic XOR", [[\oplus]]),
  symbol("inf", "Infinity", [[\infty]]),

  symbol("forall", "Forall", [[\forall]]),
  symbol("exists", "Exists", [[\exists]]),
  symbol("in", "In", [[\in]]),
  symbol("notin", "Not in", [[\notin]]),

  symbol("<=", "Less and equal", [[\le]]),
  symbol(">=", "Greater and equal", [[\ge]]),
  symbol(">>", "Much greater", [[\gg]]),
  symbol("<<", "Much less", [[\ll]]),
  symbol("!=", "Not equal", [[\neq]]),
  symbol("===", "Equivalent", [[\equiv]]),

  symbol("+-", "+-", [[\pm]]),
  symbol("-+", "-+", [[\mp]]),

  symbol("sqrt", "Sqrt", [[\sqrt]]),
  symbol("degree", "Degree", [[^\circ]]),

  symbol("hl", "Hline", [[\hline]]),

  symbol_mult({ "NN", "intersect" }, "Cap", [[\cap]]),
  symbol_mult({ "UU", "union" }, "Cup", [[\cup]]),

  big_bracket("lr", "()", "(", ")"),
  big_bracket("lr()", "()", "(", ")"),
  big_bracket("lr[]", "[]", "[", "]"),
  big_bracket("lr{}", "{}", "{", "}"),
  big_bracket("lr||", "||", "|", "|"),
  big_bracket("lr<>", "<>", "<", ">"),
}

M.autosnippets = {
  s(
    { trig = "mk", name = "math_inline", desc = "Math (inline)" },
    fmta([[\(<>\)]], { d(1, nodes_util.visual_or_insert) }),
    {
      condition = cond_has_selected_text + -math_conds.obj.in_math,
      show_condition = math_conds.obj.false_fn,
    }
  ),
  s(
    { trig = "dm", name = "math_block", desc = "Math (block)" },
    fmta(
      [[
        \[
          <>
        \]
    ]],
      { d(1, nodes_util.visual_or_insert) }
    ),
    {
      -- `dm` snippet does not need to be at the start of a line
      condition = (cond_line_begin * cond_has_selected_text) + -math_conds.obj.in_math,
      show_condition = math_conds.obj.false_fn,
    }
  ),

  s(
    { trig = "==", desc = "&= align" },
    fmta(
      [[
        &<> <> \\
      ]],
      { c(1, { t("="), t("\\leq"), i(1) }), i(2) }
    ),
    { condition = math_conds.obj.in_align, show_condition = math_conds.obj.in_align }
  ),

  postfix(
    { trig = "vec", desc = "Vector" },
    { d(1, nodes_util.dynamic_postfix, {}, { user_args = { "\\vec{", "}" } }) },
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),
  postfix(
    { trig = "hat", desc = "Hat" },
    { d(1, nodes_util.dynamic_postfix, {}, { user_args = { "\\hat{", "}" } }) },
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),
  postfix(
    { trig = "bar", desc = "Overline" },
    { d(1, nodes_util.dynamic_postfix, {}, { user_args = { "\\overline{", "}" } }) },
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),
  postfix(
    { trig = "overline", desc = "Overline" },
    { d(1, nodes_util.dynamic_postfix, {}, { user_args = { "\\overline{", "}" } }) },
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),

  postfix(
    { trig = "rm", desc = "Math rm" },
    { d(1, nodes_util.dynamic_postfix, {}, { user_args = { "\\mathrm{", "}" } }) },
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),

  -- fractions
  s(
    { trig = "//", name = "fraction", desc = "Fraction" },
    fmta([[\frac{<>}{<>}]], { i(1), i(2) }),
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),

  -- TODO: auto fraction
  -- autosnippet(
  --   {
  --     trig = "((\\d+)|(\\d*)(\\\\)?([A-Za-z]+)((\\^|_)(\\{\\d+\\}|\\d))*)\\/",
  --     name = "fraction",
  --     desc = "auto fraction 1",
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
  --   { trig = [[(^.*\\))/]], name = "fraction", desc = "auto fraction 2", trigEngine = "ecma" },
  --   { d(1, generate_fraction) },
  --   { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  -- ),

  s(
    { trig = "^^", name = "superscript", desc = "Superscript", wordTrig = false },
    fmta([[^{<>}]], { i(1) }),
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.false_fn }
  ),
  s(
    { trig = "__", name = "subscript", desc = "Subscript", wordTrig = false },
    fmta([[_{<>}]], { i(1) }),
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.false_fn }
  ),

  symbol("xx", "Times", [[\times]]),
  postfix(
    { trig = "sr", desc = "Square" },
    { fmta([[^2]], {}) },
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),
  postfix(
    { trig = "cb", desc = "Cube" },
    { fmta([[^3]], {}) },
    { condition = math_conds.obj.in_math, show_condition = math_conds.obj.in_math }
  ),
}

return M.snippets, M.autosnippets
