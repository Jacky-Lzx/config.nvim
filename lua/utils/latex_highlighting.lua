local M = {}

vim.api.nvim_create_autocmd("Syntax", {
  group = vim.api.nvim_create_augroup("lzx_latex_highlighting", { clear = true }),
  pattern = { "tex", "plaintex", "ON" },
  callback = function(event)
    if
      vim.treesitter.highlighter.active[event.buf]
      and vim.tbl_contains({ "tex", "plaintex" }, vim.bo[event.buf].filetype)
    then
      vim.bo[event.buf].syntax = ""
    end
  end,
})

function M.attach(bufnr)
  local ok, query = pcall(vim.treesitter.query.get, "latex", "highlights")
  if ok and query then
    -- Keep the priority-90 math background and priority-100 token colors.
    query.query:disable_capture("markup.math")
  end
  pcall(vim.treesitter.start, bufnr, "latex")
  -- Conceal is provided by tex-tools decorations, independently of syntax.
  vim.bo[bufnr].syntax = ""
end

return M
