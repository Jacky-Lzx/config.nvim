local s = require("snippet_tools")
local h = require("snippet_collections.tex.helpers")
local f, def, content = h.format, h.define, h.content
local math = { condition = h.math, show_condition = h.math }
local show_math, show_text = { show_condition = h.math }, { show_condition = h.not_math }
local result = {
  def(
    "align",
    "Align environment\nInsert align in text and aligned in math environment",
    f(
      [[
    \begin{<>}
      <>
    \end{<>}
  ]],
      { s.d(1, function(_, ctx)
        return s.t(h.math(ctx) and "aligned" or "align")
      end), s.i(0), s.rep(1) }
    )
  ),
  def(
    "equation",
    "Equation environment",
    f(
      [[
    \begin{equation<>}
      <>
    \end{equation<>}
  ]],
      {
        s.c(1, { "", "*" }),
        s.d(2, function(args)
          if args[1]:sub(-1) == "*" then
            return s.i(1)
          end
          return { s.i(1), s.t("\n  \\label{eq:"), s.i(2), s.t("}") }
        end, { 1 }),
        s.rep(1),
      }
    ),
    show_text
  ),
  def("ope", "operatorname", f([[\operatorname{<>}]], { content(1) }), show_math),
  def(
    "big-bracket",
    "Big bracket",
    f(
      [[
    \left\{
      \begin{array}{ll}
        <> & <> \\
        <> & <> \\
      \end{array}
    \right.
  ]],
      { s.i(1), s.i(2), s.i(3), s.i(4) }
    ),
    show_math
  ),
  def(
    "lim",
    "Lim(sup|inf)",
    f([[\lim<><>]], {
      s.c(1, { "", "sup", "inf" }),
      s.c(2, { "", f([[_{<> \to <>}]], { s.i(1, "n"), s.i(2, "\\infty") }) }),
    }),
    math
  ),
  def(
    "sum",
    "Summation",
    f([[\sum<>]], {
      s.c(1, { f([[_{<>}^{<>}]], { s.i(1, "i = 0"), s.i(2, "\\infty") }), "" }),
    }),
    show_math
  ),
  def(
    "int",
    "Integral",
    f([[\int<>]], {
      s.c(1, { f([[_{<>}^{<>}]], { s.i(1, "i = 0"), s.i(2, "\\infty") }), "" }),
    }),
    show_math
  ),
  def(
    "color",
    "Text color",
    f([[\textcolor<>{<>}]], {
      s.c(1, {
        { s.t("{"), s.i(1, "red"), s.t("}") },
        { s.t("[RGB]{"), s.i(1, "0"), s.t(","), s.i(2, "255"), s.t(","), s.i(3, "0"), s.t("}") },
      }),
      content(2),
    }),
    show_text
  ),
  def("box", "Box around equation\nNeed \\usepackage{fbox}", f([[\boxed{<>}]], { content(1) }), math),
  def(
    "array",
    "Array",
    h.environment(
      "array",
      s.d(1, function()
        return { s.t("{"), s.i(1, "ll"), s.t("}") }
      end)
    ),
    math
  ),
  def("text", "`\\text{}`", f([[\text{<>}]], { content(1) }), show_math),
  def("set", "`{ }`", f([[\{ <> \}]], { content(1) }), show_math),
  def("matrix", "Matrix\nThe matrix without close characters", h.environment("matrix"), show_math),
  def("matrix[]", "bmatrix\nThe matrix with '[]' characters", h.environment("bmatrix"), show_math),
  def("matrix()", "pmatrix\nThe matrix with '()' characters", h.environment("pmatrix"), show_math),
}
result[#result + 1] = def("=>", "Short implies", { s.t([[\Rightarrow]]) }, math)
result[#result + 1] = def("==>", "Implies", { s.t([[\implies]]) }, math)
result[#result + 1] = def("<=>", "Equivalence", { s.t([[\Leftrightarrow]]) }, math)
result[#result + 1] = def("<==>", "Long equivalence", { s.t([[\iff]]) }, math)
result[#result + 1] = def("and", "Logic AND", { s.t([[\land]]) }, math)
result[#result + 1] = def("or", "Logic OR", { s.t([[\lor]]) }, math)
result[#result + 1] = def("not", "Logic NOT", { s.t([[\lnot]]) }, math)
result[#result + 1] = def("xor", "Logic XOR", { s.t([[\oplus]]) }, math)
result[#result + 1] = def("inf", "Infinity", { s.t([[\infty]]) }, math)
result[#result + 1] = def("forall", "Forall", { s.t([[\forall]]) }, math)
result[#result + 1] = def("exists", "Exists", { s.t([[\exists]]) }, math)
result[#result + 1] = def("in", "In", { s.t([[\in]]) }, math)
result[#result + 1] = def("notin", "Not in", { s.t([[\notin]]) }, math)
result[#result + 1] = def("<=", "Less and equal", { s.t([[\le]]) }, math)
result[#result + 1] = def(">=", "Greater and equal", { s.t([[\ge]]) }, math)
result[#result + 1] = def(">>", "Much greater", { s.t([[\gg]]) }, math)
result[#result + 1] = def("<<", "Much less", { s.t([[\ll]]) }, math)
result[#result + 1] = def("!=", "Not equal", { s.t([[\neq]]) }, math)
result[#result + 1] = def("===", "Equivalent", { s.t([[\equiv]]) }, math)
result[#result + 1] = def("+-", "+-", { s.t([[\pm]]) }, math)
result[#result + 1] = def("-+", "-+", { s.t([[\mp]]) }, math)
result[#result + 1] = def("degree", "Degree", { s.t([[^\circ]]) }, math)
result[#result + 1] = def("hl", "Hline", { s.t([[\hline]]) }, math)
for _, spec in ipairs({
  { "NN", "Cap", "\\cap" },
  { "intersect", "Cap", "\\cap" },
  { "UU", "Cup", "\\cup" },
  { "union", "Cup", "\\cup" },
}) do
  result[#result + 1] = def(spec[1], spec[2], { s.t(spec[3]) }, math)
end
for _, brackets in ipairs({
  { "lr", "(", ")" },
  { "lr()", "(", ")" },
  { "lr[]", "[", "]" },
  { "lr{}", "{", "}" },
  { "lr||", "|", "|" },
  { "lr<>", "<", ">" },
}) do
  result[#result + 1] = def(
    brackets[1],
    brackets[2] .. brackets[3],
    f([[\left<> <> \right<>]], { s.t(brackets[2]), s.i(1), s.t(brackets[3]) }),
    math
  )
end
vim.list_extend(result, {
  def("mk", "Math (inline)", f([[\( <> \)]], { content(1) }), {
    auto = true,
    hidden = true,
    condition = h.inline_math,
  }),
  def(
    "dm",
    "Math (block)",
    f(
      [[
    \[
      <>
    \]
  ]],
      { content(1) }
    ),
    { auto = true, hidden = true, condition = h.display_math }
  ),
  def("==", "&= align", f([[&<> <> \\]], { s.c(1, { "=", "\\leq", s.i(1) }), s.i(2) }), {
    auto = true,
    condition = h.align,
    show_condition = h.align,
  }),
  def("//", "Fraction", f([[\frac{<>}{<>}]], { s.i(1), s.i(2) }), {
    auto = true,
    condition = h.math,
    show_condition = h.math,
  }),
  h.postfix("//", "Auto Fraction", nil, nil, true),
  -- Preserve the existing unconditional scripts, including word-internal expansion.
  def("^^", "Superscript", f([[^{<>}]], { s.i(1) }), { auto = true, word = false }),
  def("__", "Subscript", f([[_{<>}]], { s.i(1) }), { auto = true, word = false }),
  def("xx", "Times", { s.t("\\times") }, { auto = true, condition = h.math, show_condition = h.math }),
})
for _, spec in ipairs({
  { "vec", "Vector", "\\vec{", "}" },
  { "hat", "Hat", "\\hat{", "}" },
  { "bar", "Overline", "\\overline{", "}" },
  { "overline", "Overline", "\\overline{", "}" },
  { "rm", "Math rm", "\\mathrm{", "}" },
  { "sr", "Square", "", "^2" },
  { "cb", "Cube", "", "^3" },
  { "sq", "Sqrt", "\\sqrt{", "}" },
}) do
  result[#result + 1] = h.postfix(unpack(spec))
end
return result
