local nodes_util = require("templates.snippets.utils.nodes")
local math_conds = require("templates.snippets.tex.utils.math_conditions")

return {
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

  s({ trig = "it", desc = "Italic text" }, fmta([[\textit{<>}]], { d(1, nodes_util.visual_or_insert) })),
  s({ trig = "bf", desc = "Bold text" }, fmta([[\textbf{<>}]], { d(1, nodes_util.visual_or_insert) })),
  s({ trig = "emph", desc = "Emph text" }, fmta([[\emph{<>}]], { d(1, nodes_util.visual_or_insert) })),

  s(
    { trig = "box", desc = { "Box around text", "\tNeed `\\usepackage{fbox}`" } },
    fmta([[\fbox{<>}]], { d(1, nodes_util.visual_or_insert) }),
    {
      condition = -math_conds.obj.in_math,
      show_condition = -math_conds.obj.in_math,
    }
  ),
  s(
    { trig = "box2", desc = { "Box around text (with line break)", "\tNeed `\\usepackage{fbox}`" } },
    fmta(
      [[
        \fbox{\parbox{0.4\textwidth}{%
          <>
        }}
    ]],
      { d(1, nodes_util.visual_or_insert) }
    ),
    {
      condition = -math_conds.obj.in_math,
      show_condition = -math_conds.obj.in_math,
    }
  ),

  s({ trig = "verb", desc = "Verb" }, fmta([[\verb|<>|]], { d(1, nodes_util.visual_or_insert) }), {
    condition = -math_conds.obj.in_math,
    show_condition = -math_conds.obj.in_math,
  }),

  s(
    { trig = "resize", desc = "Resize-box" },
    fmta(
      [[
        \resizebox*{\textwidth}{!}{%
          <>
        }
      ]],
      { d(1, nodes_util.visual_or_insert) }
    )
  ),
  s(
    { trig = "scale", desc = "Scale box" },
    fmta(
      [[
        \scalebox{0.8}{%
          <>
        }
      ]],
      { d(1, nodes_util.visual_or_insert) }
    )
  ),

  s(
    { trig = "ladd", desc = "Lzx add" },
    fmta([[\ldel{<>}\ladd{<>}]], { d(1, nodes_util.visual_or_insert, {}, { user_args = { false } }), i(0) })
  ),
  s(
    { trig = "ldel", desc = "Lzx del" },
    fmta([[\ldel{<>}]], { d(1, nodes_util.visual_or_insert, {}, { user_args = { false } }) })
  ),

  s({ trig = "ignore", desc = "tex-fmt ignore" }, { t("% tex-fmt: skip") }),
  s({ trig = "ignoreb", desc = "tex-fmt ignore (block)" }, { t("% tex-fmt: off"), t({ "", "% tex-fmt: on" }) }),
},
-- Autosnippets
{}
