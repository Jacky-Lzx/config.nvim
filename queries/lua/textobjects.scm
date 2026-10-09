(function_declaration
  body: (block)? @function.inner) @function.outer

(function_definition
  body: (block)? @function.inner) @function.outer

(_
  (block) @block.inner) @block.outer
