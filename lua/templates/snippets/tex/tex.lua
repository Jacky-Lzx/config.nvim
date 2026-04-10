local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta

local temple = require("templates.snippets.utils.utils")

return {
  -- s({ trig = "figure", desc = "Image" }, {
  --   t("!["), i(1, "content"), t({ "](./Figures_markdown/" }), i(0), t(")")
  -- }),

  -- stylua: ignore
  s({trig = "template", desc = "Template LaTeX file" },
    fmta([[
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
    ]], {i(0)})
  ),

  s({ trig = "par", desc = "Paragraph" }, { t("\\par ") }),

  s(
    { trig = "it", desc = "italic" },
    fmta(
      [[
        \textit{<>}
      ]],
      { i(1) }
    )
  ),
  s(
    { trig = "bf", desc = "bold" },
    fmta(
      [[
        \textbf{<>}
      ]],
      { i(1) }
    )
  ),
}
