-- Keep long LaTeX lines intact while typing.
vim.opt_local.textwidth = 0
vim.opt_local.wrapmargin = 0
vim.opt_local.formatoptions:remove({ "t", "c" })

if not require("languages").is_enabled("latex") then
  return
end

require("languages.latex.buffer").setup(vim.api.nvim_get_current_buf())
