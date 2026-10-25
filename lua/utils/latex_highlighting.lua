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

-- Tree-sitter owns syntax colors; semantic tokens add variable identity.
-- Scope the policy to TeX so other languages keep their theme's semantic
-- highlighting, including standalone BibTeX buffers.
local function semantic_highlights()
  local types = { "macro", "variable", "type", "enumMember", "string", "comment", "property", "number", "operator" }
  for _, ft in ipairs({ "tex", "plaintex" }) do
    for _, kind in ipairs(types) do
      local base = "@lsp.type." .. kind .. "." .. ft
      vim.api.nvim_set_hl(0, base, kind == "variable" and { link = "@variable" } or {})
      -- Clear declaration styling, including combined type/modifier groups
      -- that a theme may define independently of the base token.
      vim.api.nvim_set_hl(0, "@lsp.typemod." .. kind .. ".declaration." .. ft, {})
    end
    vim.api.nvim_set_hl(0, "@lsp.mod.declaration." .. ft, {})
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = "lzx_latex_highlighting",
  callback = semantic_highlights,
})

function M.attach(bufnr)
  semantic_highlights()
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
