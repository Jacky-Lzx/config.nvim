; extends

; Math separators and sized delimiters override the surrounding math color.
((delimiter) @punctuation.delimiter
  (#set! priority 110))

((math_delimiter
  left_command: _ @punctuation.delimiter
  left_delimiter: _ @punctuation.delimiter
  right_command: _ @punctuation.delimiter
  right_delimiter: _ @punctuation.delimiter)
  (#set! priority 110))

; Environment boundaries keep their syntax colors inside math environments.
; The upstream @markup.math capture also covers these nodes at priority 100.
((begin
  command: _ @module
  name: (curly_group_text
    "{" @punctuation.bracket
    (text) @label
    "}" @punctuation.bracket))
  (#set! priority 110))

((end
  command: _ @module
  name: (curly_group_text
    "{" @punctuation.bracket
    (text) @label
    "}" @punctuation.bracket))
  (#set! priority 110))
