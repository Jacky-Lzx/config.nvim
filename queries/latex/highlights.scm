; extends

; The original @markup.math capture is disabled by utils.latex_highlighting.
; The dotted capture falls back to the theme's @markup.math color, while
; specific commands, references and punctuation retain priority 100.
([
  (displayed_equation)
  (inline_formula)
] @markup.math.background
  (#set! priority 90))

((math_environment
  (_) @markup.math.background)
  (#set! priority 90))
