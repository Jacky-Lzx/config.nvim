-- Personal snippet conditions; language plugins own structural queries.
local M = { fn = {} }
local function tex()
  return vim.bo.filetype == "tex" or vim.bo.filetype == "plaintex"
end
function M.fn.math_mode()
  if tex() then
    return require("tex-tools").in_math()
  end
  if vim.bo.filetype == "markdown" or vim.bo.filetype == "markdown_inline" then
    return require("markdown_tools").in_math()
  end
  return false
end
M.fn.in_math = M.fn.math_mode
function M.fn.is_latex()
  return vim.bo.filetype == "tex"
end
function M.fn.in_beamer()
  if not tex() then
    return false
  end
  local class = require("tex-tools").document_class()
  return class == "beamer" or class == "ctexbeamer"
end
local function environment(names)
  return function()
    return tex() and require("tex-tools").in_environment(names) or false
  end
end
M.fn.in_align = environment({ "align", "align*", "aligned" })
M.fn.in_figure = environment({ "figure", "figure*" })
M.fn.in_bullets = environment({ "itemize", "enumerate" })
return M
