if not require("languages").is_enabled("latex") then
  return
end

require("languages.latex.buffer").setup(vim.api.nvim_get_current_buf())
