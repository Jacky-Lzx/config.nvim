local M = {}

-- Keep syntax matches (including conceal), but let Tree-sitter supply colors.
function M.clear_syntax_styles()
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    if name:match("^tex[A-Z]") then
      vim.api.nvim_set_hl(0, name, {})
    end
  end
end

local group = vim.api.nvim_create_augroup("lzx_latex_highlighting", { clear = true })
local function clear_later()
  vim.schedule(M.clear_syntax_styles)
end

vim.api.nvim_create_autocmd("Syntax", {
  group = group,
  pattern = { "tex", "ON" },
  callback = clear_later,
})
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = clear_later,
})
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "VimtexEventInitPost",
  callback = clear_later,
})

function M.attach(bufnr)
  local ok, query = pcall(vim.treesitter.query.get, "latex", "highlights")
  if ok and query then
    -- Replace only this broad capture; retain all upstream token rules.
    -- queries/latex/highlights.scm supplies @markup.math.background at 90.
    query.query:disable_capture("markup.math")
  end

  pcall(vim.treesitter.start, bufnr, "latex")
  -- Tree-sitter clears 'syntax' on startup. Restore it for VimTeX conceal.
  vim.bo[bufnr].syntax = "tex"
  M.clear_syntax_styles()
  clear_later()
end

return M
