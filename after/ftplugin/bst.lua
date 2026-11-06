if require("languages").is_enabled("latex") then
  require("languages.latex.buffer").setup_actions(vim.api.nvim_get_current_buf())
end
