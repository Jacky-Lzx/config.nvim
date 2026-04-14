local math_conditions = require("templates.snippets.tex.utils.math_conditions")

return {
  s(
    { trig = "frame", desc = "Frame" },
    fmta(
      [[
        \begin{frame}<><>
          <>
        \end{frame}
      ]],
      { c(2, { t(""), t("[fragile]") }), c(1, { sn(nil, { t("{"), i(1, "Title"), t("}") }), t("") }), i(0) }
    ),
    { condition = math_conditions.obj.in_beamer, show_condition = math_conditions.obj.in_beamer }
  ),

  s(
    { trig = "toc", desc = "Table of contents" },
    fmta(
      [[
        \begin{frame}{<>}
          \tableofcontents
        \end{frame}
        % Current section
        \AtBeginSection[ ]
        {
          \begin{frame}{<>}
            \tableofcontents[currentsection]
          \end{frame}
        }
      ]],
      { i(1, "Outline"), rep(1) }
    ),
    { condition = math_conditions.obj.in_beamer, show_condition = math_conditions.obj.in_beamer }
  ),

  s(
    { trig = "columns", desc = "Create columns" },
    fmta(
      [[
        \begin{columns}
          \begin{column}{0.<>\linewidth}
            <>
          \end{column}

          \begin{column}{0.<>\linewidth}
            <>
          \end{column}
        \end{columns}
      ]],
      { i(1, "5"), i(3), i(2, "5"), i(0) }
    ),
    { condition = math_conditions.obj.in_beamer, show_condition = math_conditions.obj.in_beamer }
  ),
}
