local ls = require("luasnip")

local nodes_util = require("templates.snippets.utils.nodes")
local conds = require("templates.snippets.tex.utils.math_conditions")
local cond_line_begin = require("luasnip.extras.conditions.expand").line_begin

local function label_fn(args, _, _)
  -- Remove extension str
  local ret = args[1][1]:gsub("%.[^.]*$", "")
  -- Change `_` to `-`
  --  NOTE: This is a bug of the LaTeX treesiter parser. `_` breaks the treesitter parsing
  --        Link: `https://github.com/latex-lsp/tree-sitter-latex/issues/208`
  --        <2026.04.14, lzx>
  ret = ret:gsub("_", "-")
  return ret
end

-- local tex = require("templates.snippets.tex.utils.conditions")

return {
  s(
    { trig = "begin", name = "begin/end", desc = "begin/end" },
    fmta(
      [[
          \begin{<>}
            <>
          \end{<>}
    ]],
      { i(1), i(0), rep(1) }
    ),
    { show_condition = conds.obj.is_latex }
  ),

  s(
    { trig = "itemize", name = "itemize", desc = "Itemize" },
    fmta(
      [[
        \begin{itemize}<>
          \item <>
        \end{itemize}
      ]],
      {
        c(1, {
          i(1),
          t("[leftmargin=0.5cm]"),
        }),
        i(0),
      }
    ),
    { show_condition = conds.obj.is_latex }
  ),

  s(
    { trig = "item", name = "item", desc = "A single item" },
    { t("\\item ") },
    { condition = conds.obj.in_bullets, show_condition = conds.obj.in_bullets }
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

  s(
    { trig = "enumerate", name = "enumerate", desc = "Enumerate" },
    fmta(
      [[
      \begin{enumerate}<>
        \item <>
      \end{enumerate}
      ]],
      {
        c(1, {
          t("[label=\\arabic*.]"),
          t("[label=\\alph*.]"),
          t("[label=\\roman*.]"),
          i(1),
        }),
        i(0),
      }
    ),
    { show_condition = conds.obj.is_latex }

    -- { condition = tex.in_text, show_condition = tex.in_text }
  ),

  s(
    { trig = "figure", name = "figure", desc = "Figure environment" },
    fmta(
      [[
        \begin{figure}[<>]
          \centering
          \includegraphics[width=0.<>\linewidth]{<><>}
          \caption{<>}%
          \label{fig:<>}
        \end{figure}
      ]],
      {
        c(1, { t("H"), t("htbp") }),
        i(2, "6"),
        t("./Figures/"),
        i(3),
        i(4),
        f(label_fn, { 3 }),
      }
    ),
    { show_condition = conds.obj.is_latex }
  ),

  s(
    { trig = "table", name = "table", desc = "Table environment" },
    fmta(
      [[
        \begin{table}[<>]
          \centering
          \begin{tabular}{<>}
            <>
          \end{tabular}
          \caption{<>}
          \label{tab:<>}
        \end{table}
      ]],
      {
        c(1, { t("H"), t("htbp") }),
        i(2, "cc"),
        i(0),
        i(3),
        i(4),
      }
    ),
    { show_condition = conds.obj.is_latex }
  ),

  s(
    { trig = "subfigure", desc = "Subfigure" },
    fmta(
      [[
        \begin{figure}[H]
          \centering
          \begin{subfigure}[b]{0.45\textwidth}
            \centering
            \includegraphics[width=\textwidth]{<><>}
            \caption{<>}
            \label{subfig:<>}
          \end{subfigure}
          \begin{subfigure}[b]{0.45\textwidth}
            \centering
            \includegraphics[width=\textwidth]{<><>}
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
        f(label_fn, { 1 }),
        t("./Figures/"),
        i(3),
        i(4),
        f(label_fn, { 3 }),
        i(5),
        i(6),
      }
    ),
    { show_condition = conds.obj.is_latex * -conds.obj.in_figure }
  ),

  s(
    { trig = "subfigure", desc = "Subfigure (simple)" },
    fmta(
      [[
        \begin{subfigure}[b]{0.45\textwidth}
          \centering
          \includegraphics[width=\textwidth]{<><>}
          \caption{<>}
          \label{subfig:<>}
        \end{subfigure}
      ]],
      {
        t("./Figures/"),
        i(1),
        i(2),
        f(label_fn, { 1 }),
      }
    ),
    { show_condition = conds.obj.is_latex * conds.obj.in_figure }
  ),

  s(
    { trig = "verbatim", name = "verbatim", desc = "Verbatim environment" },
    nodes_util.fmt_env("verbatim"),
    { show_condition = conds.obj.is_latex * conds.obj.in_figure }
  ),
}, {
  s({ trig = ";t", desc = "`\\item `" }, { t("\\item ") }, { condition = conds.obj.is_latex }),
}
