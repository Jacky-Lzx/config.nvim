local s = require("snippet_tools")
local h = require("snippet_collections.tex.helpers")
local f, def, content = h.format, h.define, h.content
local latex, text = { show_condition = h.latex }, { show_condition = h.not_math }
return {
  def(
    "template",
    "Template LaTeX file",
    f(
      [[
      \documentclass[a4paper]{article}

      \usepackage[utf8]{inputenc}
      \usepackage[T1]{fontenc}

      %\setlength{\parskip}{0.5\baselineskip}

      \usepackage{geometry}
      \geometry{left = 2.54 cm, right = 2.54 cm, top = 2.54 cm, bottom = 2.54 cm}

      \usepackage{indentfirst}
      \setlength{\parindent}{2em}

      %\usepackage{fontspec}
      %\setmainfont{Times New Roman}

      \PassOptionsToPackage{hyphens}{url}
      \usepackage[colorlinks=true]{hyperref}
      \usepackage{ulem}
      \usepackage{graphicx}
      %\usepackage{wrapfig}
      \usepackage{enumitem}
      %\usepackage{xcolor}
      %\usepackage{subcaption}
      \usepackage{float}
      \usepackage{amsmath, amssymb, amsthm}
      \usepackage{booktabs}

      %\pagestyle{empty} % Not showing page number


      \newcommand{\TODO}[1]{\textcolor{red}{TODO\@: #1} }

      \renewcommand{\thesection}{\Roman{section}}
      \renewcommand{\thesubsection}{\Alph{subsection}}
      \renewcommand{\thesubsubsection}{\thesubsection.\arabic{subsubsection}}
      \renewcommand{\d}{ \: \mathrm{d} }
      \newcommand{\e}{\mathrm{e}}

      \begin{document}

        <>

      \end{document}
    ]],
      { s.i(0) }
    ),
    latex
  ),
  def("par", "Paragraph", { s.t("\\par ") }, latex),
  def("it", "Italic text", f([[\textit{<>}]], { content(1) }), latex),
  def("bf", "Bold text", f([[\textbf{<>}]], { content(1) }), latex),
  def("emph", "Emph text", f([[\emph{<>}]], { content(1) }), latex),
  def("box", "Box around text\nNeed \\usepackage{fbox}", f([[\fbox{<>}]], { content(1) }), text),
  def(
    "box2",
    "Box around text (with line break)\nNeed \\usepackage{fbox}",
    f(
      [[
    \fbox{\parbox{0.4\textwidth}{%
      <>
    }}
  ]],
      { content(1) }
    ),
    text
  ),
  def("verb", "Verb", f([[\verb|<>|]], { content(1) }), text),
  def(
    "resize",
    "Resize-box",
    f(
      [[
    \resizebox*{\textwidth}{!}{%
      <>
    }
  ]],
      { content(1) }
    ),
    latex
  ),
  def(
    "scale",
    "Scale box",
    f(
      [[
    \scalebox{0.8}{%
      <>
    }
  ]],
      { content(1) }
    ),
    latex
  ),
  def("vs", "vspace", f([[\vspace{<>em}]], { s.i(0, "-1") }), latex),
  def("ladd", "Lzx add", f([[\ldelA{<>}\laddA{<>}]], { content(1, false), s.i(0) }), latex),
  def("ldel", "Lzx del", f([[\ldelA{<>}]], { content(1, false) }), latex),
  def("ignore", "tex-fmt ignore", { s.t("% tex-fmt: skip") }, latex),
  def("ignoreb", "tex-fmt ignore (block)", { s.t("% tex-fmt: off\n% tex-fmt: on") }, latex),
}
