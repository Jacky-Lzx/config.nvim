local s = require("snippet_tools")
local h = require("snippet_collections.tex.helpers")
local f, def = h.format, h.define
local beamer = { condition = h.beamer, show_condition = h.beamer }
return {
  def(
    "frame",
    "Frame",
    f(
      [[
    \begin{frame}<><>
      <>
    \end{frame}
  ]],
      { s.c(2, { "", "[fragile]", "[t]" }), s.c(1, { { s.t("{"), s.i(1, "Title"), s.t("}") }, "" }), s.i(0) }
    ),
    beamer
  ),
  def(
    "toc",
    "Table of contents",
    f(
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
      { s.i(1, "Outline"), s.rep(1) }
    ),
    beamer
  ),
  def(
    "columns",
    "Create columns",
    f(
      [[
    \begin{columns}[T,totalwidth=\linewidth]
      \begin{column}{0.<>\linewidth}
        <>
      \end{column}

      \begin{column}{0.<>\linewidth}
        <>
      \end{column}
    \end{columns}
  ]],
      {
        s.i(1, "49"),
        s.i(2),
        s.f(function(args)
          local val = tonumber("0." .. args[1])
          if val and val <= 0.98 then
            local digits = string.format("%.6f", 0.98 - val):sub(3):gsub("0+$", "")
            return digits ~= "" and digits or "0"
          end
          return "49"
        end, { 1 }),
        s.i(0),
      }
    ),
    beamer
  ),
}
