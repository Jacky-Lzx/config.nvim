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
      { c(2, { t(""), t("[fragile]"), t("[t]") }), c(1, { sn(nil, { t("{"), i(1, "Title"), t("}") }), t("") }), i(0) }
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
        \begin{columns}[onlytextwidth, T]
          \begin{column}{0.<>\textwidth}
            <>
          \end{column}

          \begin{column}{0.<>\textwidth}
            <>
          \end{column}
        \end{columns}
      ]],
      {
        i(1, "5"),
        i(2),
        f(function(args)
          local val = tonumber("0." .. args[1][1])
          if val then
            local new_val = 1 - val
            return tostring(1 - val):sub(3)
          end
          return "5" -- Default fallback
        end, { 1 }),
        i(0),
      }
    ),
    { condition = math_conditions.obj.in_beamer, show_condition = math_conditions.obj.in_beamer }
  ),
}
