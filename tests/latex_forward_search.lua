-- nvim --clean --headless -n -i NONE -l tests/latex_forward_search.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(debug.getinfo(1, "S").source:sub(2))))
vim.opt.runtimepath:prepend(root)
vim.g.maplocalleader = " "
package.loaded["utils.platform"] = { executable = function() end }
package.loaded["utils.latex_highlighting"] = { attach = function() end }
package.loaded["which-key"] = { add = function() end }
package.loaded["integrations.bibtex_preview"] = { setup = function() end }
package.loaded["languages.latex.linked_editing"] = { attach = function() end }
local spec = require("languages.latex.plugins")
assert(spec[2][1] == "Jacky-Lzx/tex-tools.nvim")
assert(spec[2].opts.lsp == "texquill" and spec[2].opts.viewer.focus == false)
local called = 0
vim.api.nvim_create_user_command("TexToolsForwardSearch", function()
  called = called + 1
end, {})
vim.api.nvim_create_user_command("TexToolsView", function()
  called = called + 1
end, {})
vim.bo.filetype = "tex"
local bufnr = vim.api.nvim_get_current_buf()
local function verify()
  assert(vim.fn.maparg(" lv", "n") == "<Cmd>TexToolsForwardSearch<CR>")
  assert(vim.fn.maparg(" lV", "n") == "<Cmd>TexToolsView<CR>")
  vim.api.nvim_feedkeys(" lv lV", "xt", false)
end
require("languages.latex.buffer").setup(bufnr)
verify()
require("languages.latex.lsp").attach({}, bufnr)
verify()
assert(called == 4)
print("LaTeX forward search passed: focus preference and both mappings delegate to tex-tools")
