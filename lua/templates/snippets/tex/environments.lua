local ls = require("luasnip")

local nodes_util = require("templates.snippets.utils.nodes")
local math_conds = require("templates.snippets.tex.utils.math_conditions")
local cond_line_begin = require("luasnip.extras.conditions.expand").line_begin

-- local tex = require("templates.snippets.tex.utils.conditions")

return {
  -- stylua: ignore
  s({ trig = "begin", name = "begin/end", desc = "begin/end" },
    fmta([[
          \begin{<>}
            <>
          \end{<>}
    ]], { i(1), i(0), rep(1) })
  ),

  -- stylua: ignore
  s({ trig = "itemize", name = "itemize", desc = "Itemize" },
    fmta([[
        \begin{itemize}<>
          \item <>
        \end{itemize}
      ]], {
        c(1, {
          i(1),
          t("[leftmargin=0.5cm]"),
        }),
        i(0)
      }
    )
    -- { condition = tex.in_text, show_condition = tex.in_text }
  ),

  s(
    { trig = "item", name = "item", desc = "A single item" },
    { t("\\item ") },
    { condition = math_conds.obj.in_bullets, show_condition = math_conds.obj.in_bullets }
  ),
  -- autosnippet(
  --   { trig = "--", hidden = true },
  --   { t("\\item ") },
  --   {
  --     condition = math_conds.obj.in_bullets * cond_line_begin,
  --     show_condition = math_conds.obj.in_bullets * cond_line_begin,
  --   }
  --   -- { condition = cond_line_begin, show_condition = cond_line_begin }
  -- ),

  -- stylua: ignore
  s({ trig = "enumerate", name = "enumerate", desc = "Enumerate" },
    fmta([[
      \begin{enumerate}<>
        \item <>
      \end{enumerate}
      ]], {
        c(1, {
          t("[label=\\arabic*.]"),
          t("[label=\\alph*.]"),
          t("[label=\\roman*.]"),
          i(1),
        }),
        i(0)
      }
    )
    -- { condition = tex.in_text, show_condition = tex.in_text }
  ),

  -- stylua: ignore
  s({ trig = "figure", name = "figure", desc = "Figure environment" },
    fmta([[
        \begin{figure}[<>]
          \centering
          \includegraphics[width=0.<>\linewidth]{<><>}
          \caption{<>}%
          \label{fig:<>}
        \end{figure}
      ]],{
        c(1, { t("H"), t("htbp") }),
        i(2, "6"),
        t("./Figures/"),
        i(3),
        i(4),
        f(function(args, _, _)
          -- Remove extension str
          return args[1][1]:gsub("%.[^.]*$", "")
        end, { 3 }),
      }
    )
  ),

  -- stylua: ignore
  s({ trig = "table", name = "table", desc = "Table environment" },
    fmta([[
        \begin{table}[<>]
          \centering
          \begin{tabular}{<>}
            <>
          \end{tabular}
          \caption{<>}
          \label{tab:<>}
        \end{table}
      ]], {
        c(1, { t("H"), t("htbp") }),
        i(2, "cc"),
        i(0),
        i(3),
        i(4),
      }
    )
  ),

  s(
    { trig = "subfigure", desc = "Subfigure" },
    fmta(
      [[
        \begin{figure}[H]
          \centering
          \begin{subfigure}[b]{0.45\linewidth}
            \centering
            \includegraphics[width=0.9\linewidth]{<><>}
            \caption{<>}
            \label{subfig:<>}
          \end{subfigure}
          \begin{subfigure}[b]{0.45\linewidth}
            \centering
            \includegraphics[width=0.9\linewidth]{<><>}
            \caption{<>}
            \label{subfig:<>}
          \end{subfigure}
          \caption{<>}
          \label{fig:<>}
        \end{figure}
      ]],
      {
        t("./Figures/"),
        i(1),
        i(2),
        f(function(args, _, _)
          -- Remove extension str
          return args[1][1]:gsub("%.[^.]*$", "")
        end, { 1 }),
        t("./Figures/"),
        i(3),
        i(4),
        f(function(args, _, _)
          -- Remove extension str
          return args[1][1]:gsub("%.[^.]*$", "")
        end, { 3 }),
        i(5),
        i(6),
      }
    ),
    { condition = -math_conds.obj.in_figure, show_condition = -math_conds.obj.in_figure }
  ),

  s(
    { trig = "subfigure", desc = "Subfigure (simple)" },
    fmta(
      [[
        \begin{subfigure}[b]{0.45\linewidth}
          \centering
          \includegraphics[width=0.9\linewidth]{<><>}
          \caption{<>}
          \label{subfig:<>}
        \end{subfigure}
      ]],
      {
        t("./Figures/"),
        i(1),
        i(2),
        f(function(args, _, _)
          -- Remove extension str
          return args[1][1]:gsub("%.[^.]*$", "")
        end, { 1 }),
      }
    ),
    { condition = math_conds.obj.in_figure, show_condition = math_conds.obj.in_figure }
  ),

  s({ trig = "verbatim", name = "verbatim", desc = "Verbatim environment" }, nodes_util.fmt_env("verbatim")),
}
