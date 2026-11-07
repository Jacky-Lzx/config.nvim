-- nvim --clean --headless -n -i NONE -l tests/native/latex_forward_search.lua
local root = vim.fs.root(vim.fs.abspath(debug.getinfo(1, "S").source:sub(2)), "init.lua")
vim.opt.runtimepath:prepend(root)
vim.g.maplocalleader, vim.g.mapleader = " ", " "
package.loaded["utils.platform"] = { executable = function() end }
local registration
package.loaded["keymap_tools"] = {
  register = function(source, spec)
    if source:find("config.toggle.tex_build_on_save:", 1, true) == 1 then
      registration = spec
    end
  end,
}
package.loaded["languages.latex.linked_editing"] = { attach = function() end }
local spec = require("languages.latex.plugins")
assert(spec[2].source == "Jacky-Lzx/tex-tools.nvim")
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
local before = vim.fn.maparg(" ll", "n", false, true)
require("languages.latex.lsp")
assert(vim.deep_equal(before, vim.fn.maparg(" ll", "n", false, true)), "LSP attachment replaced the build mapping")
assert(vim.fn.maparg("<leader>lb", "n") == "<Cmd>TexToolsBuild<CR>")
assert(type(vim.fn.maparg(" txa", "n", false, true).callback) == "function")
assert(vim.fn.maparg(" la", "n") == "")
assert(registration.buf == bufnr)
local get = registration.toggles[1].get
assert(get({ buf = bufnr }) == nil, "Cold state inspection must not load tex-tools")
package.loaded["tex-tools"] = {
  build_on_save_enabled = function(buf)
    return buf == bufnr
  end,
}
assert(get({ buf = bufnr }) == true)
package.loaded["tex-tools"] = nil
verify()
assert(called == 4)
vim.cmd.enew()
local bib = vim.api.nvim_get_current_buf()
require("languages.latex.buffer").setup_actions(bib)
assert(vim.fn.maparg(" ll", "n") == "<Cmd>TexToolsBuild<CR>")
assert(vim.fn.maparg(" lq", "n") == "<Cmd>TexToolsLog<CR>")
assert(vim.fn.maparg("ie", "o") == "", "Bibliography actions installed TeX structural objects")
vim.bo.filetype = "bib"
local builds = 0
package.loaded["tex-tools"] = {
  build = function()
    builds = builds + 1
    return true
  end,
}
require("languages.latex.buffer").setup_actions(bib)
vim.fn.maparg(" ll", "n", false, true).callback()
assert(builds == 1, "Bibliography builds must reach the shared public API")
package.loaded["tex-tools"] = nil
print(
  "LaTeX forward search passed: focus preference, native mappings and plugin-owned builds and cold state inspection"
)
