if require("languages").is_enabled("latex") then
  require("languages.latex.buffer").setup(vim.api.nvim_get_current_buf())
end
