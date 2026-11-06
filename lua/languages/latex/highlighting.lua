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
  if vim.b[bufnr].config_treesitter_disabled then
    return false, "Tree-sitter is disabled for this buffer"
  end
  local previous = vim.bo[bufnr].syntax
  local ok, err = pcall(vim.treesitter.start, bufnr, "latex")
  if ok then
    -- Conceal is provided by tex-tools decorations, independently of syntax.
    vim.bo[bufnr].syntax = ""
    return true
  end
  -- A failed query/parser initialization may have already changed syntax.
  pcall(vim.treesitter.stop, bufnr)
  vim.bo[bufnr].syntax = previous ~= "" and previous or (vim.bo[bufnr].filetype == "plaintex" and "plaintex" or "tex")
  return false, err
end

return M
