local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
dofile(root .. "/tests/support/setup.lua")
dofile(root .. "/init.lua")
dofile(root .. "/tests/support/native_plugins.lua")
local ui = require("completion_tools.ui")
local cfg = require("completion_tools.config").validate(require("integrations.completion").options())
ui.render({ { item = { label = "fixture" }, source_id = "lsp", start_col = 0 } }, 1, {
  winid = vim.api.nvim_get_current_win(),
  bufnr = 0,
  row = 0,
  col = 0,
  start_col = 0,
  mode = "insert",
  before = "",
  line = "",
  filetype = "tex",
}, cfg)
local raw = { "```bibtex", "", "@book{fixture,", "}", "", "```" }
assert(ui.documentation({ documentation = table.concat(raw, "\n") }, cfg))
local ns = vim.api.nvim_create_namespace("bibtex-preview-spacing")
local doc
for _, win in ipairs(vim.api.nvim_list_wins()) do
  local buf = vim.api.nvim_win_get_buf(win)
  if #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) > 0 then
    doc = { buf = buf, win = win }
  end
end
assert(doc and vim.api.nvim_win_get_height(doc.win) == 2, "Completion kept BibTeX padding")
assert(ui.documentation({ documentation = "ordinary\n\ndocumentation" }, cfg))
assert(#vim.api.nvim_buf_get_extmarks(doc.buf, ns, 0, -1, {}) == 0, "Reused pane kept old conceal marks")
ui.hide()
local buf, win = vim.lsp.util.open_floating_preview(raw, "markdown", { focus_id = "textDocument/hover" })
assert(#vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) == 6, "Native hover hook did not compact padding and fences")
assert(vim.api.nvim_win_get_height(win) == 2)
vim.api.nvim_win_close(win, true)
local other, other_win = vim.lsp.util.open_floating_preview(raw, "markdown", {})
local flushed = false
vim.schedule(function()
  flushed = true
end)
assert(vim.wait(1000, function()
  return flushed
end))
assert(#vim.api.nvim_buf_get_extmarks(other, ns, 0, -1, {}) == 0, "Unrelated float was compacted")
vim.api.nvim_win_close(other_win, true)
assert(vim.fn.exists("#BibtexPreviewSpacing") == 0)
print("Document render: scoped callbacks, BibTeX spacing, reuse cleanup and unrelated float isolation passed")
