local s = require("snippet_tools")
local h = require("snippet_collections.tex.helpers")
local f, def = h.format, h.define
local latex = { show_condition = h.latex }
return {
  def(
    "begin",
    "begin/end",
    f(
      [[
    \begin{<>}
      <>
    \end{<>}
  ]],
      { s.i(1), s.i(0), s.rep(1) }
    ),
    latex
  ),
  def(
    "itemize",
    "Itemize",
    f(
      [[
    \begin{itemize}<>
      \item <>
    \end{itemize}
  ]],
      { s.c(1, { s.i(1), "[leftmargin=0.5cm]" }), s.i(0) }
    ),
    latex
  ),
  def("item", "A single item", { s.t("\\item ") }, { condition = h.bullets, show_condition = h.bullets }),
  def(
    "enumerate",
    "Enumerate",
    f(
      [[
    \begin{enumerate}<>
      \item <>
    \end{enumerate}
  ]],
      { s.c(1, { "[label=\\arabic*.]", "[label=\\alph*.]", "[label=\\roman*.]", s.i(1) }), s.i(0) }
    ),
    latex
  ),
  def(
    "figure",
    "Figure environment",
    f(
      [[
    \begin{figure}[<>]
      \centering
      \includegraphics[width=0.<>\linewidth]{./Figures/<>}
      \caption{<>}%
      \label{fig:<>}
    \end{figure}
  ]],
      { s.c(1, { "H", "htbp" }), s.i(2, "6"), s.i(3), s.i(4), s.f(h.label, { 3 }) }
    ),
    latex
  ),
  def(
    "table",
    "Table environment",
    f(
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
      { s.c(1, { "H", "htbp" }), s.i(2, "cc"), s.i(0), s.i(3), s.i(4) }
    ),
    latex
  ),
  def(
    "subfigure",
    "Subfigure",
    f(
      [[
    \begin{figure}[H]
      \centering
      \begin{subfigure}[b]{0.45\textwidth}
        \centering
        \includegraphics[width=\textwidth]{./Figures/<>}
        \caption{<>}
        \label{subfig:<>}
      \end{subfigure}
      \begin{subfigure}[b]{0.45\textwidth}
        \centering
        \includegraphics[width=\textwidth]{./Figures/<>}
        \caption{<>}
        \label{subfig:<>}
      \end{subfigure}
      \caption{<>}
      \label{fig:<>}
    \end{figure}
  ]],
      { s.i(1), s.i(2), s.f(h.label, { 1 }), s.i(3), s.i(4), s.f(h.label, { 3 }), s.i(5), s.i(6) }
    ),
    {
      show_condition = function(ctx)
        return h.latex(ctx) and not h.figure(ctx)
      end,
    }
  ),
  def(
    "subfigure",
    "Subfigure (simple)",
    f(
      [[
    \begin{subfigure}[b]{0.45\textwidth}
      \centering
      \includegraphics[width=\textwidth]{./Figures/<>}
      \caption{<>}
      \label{subfig:<>}
    \end{subfigure}
  ]],
      { s.i(1), s.i(2), s.f(h.label, { 1 }) }
    ),
    {
      show_condition = function(ctx)
        return h.latex(ctx) and h.figure(ctx)
      end,
    }
  ),
  def("verbatim", "Verbatim environment", h.environment("verbatim"), {
    show_condition = function(ctx)
      return h.latex(ctx) and h.figure(ctx)
    end,
  }),
  def(";t", "`\\item `", { s.t("\\item ") }, { auto = true, condition = h.latex }),
}
