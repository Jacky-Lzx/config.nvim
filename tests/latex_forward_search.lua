-- nvim --clean --headless -n -i NONE -l tests/latex_forward_search.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(debug.getinfo(1, "S").source:sub(2))))
vim.opt.runtimepath:prepend(root)
vim.g.maplocalleader = " "
package.loaded["utils.platform"] = { executable = function() end }
package.loaded["languages.latex.highlighting"] = { attach = function() end }
local registration
package.loaded["keymap_tools"] = {
  register = function(source, spec)
    if source == "latex.build-on-save" then
      registration = spec
    end
  end,
}
package.loaded["integrations.bibtex_preview"] = { setup = function() end }
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
local client = { id = 123, settings = { latex = { build = { onSave = true } } } }
local accepted = true
function client:notify(method, params)
  assert(method == "workspace/didChangeConfiguration")
  assert(type(params.settings.latex.build.onSave) == "boolean")
  return accepted
end
local get_client = vim.lsp.get_client_by_id
vim.lsp.get_client_by_id = function(id)
  return id == client.id and client or nil
end
require("languages.latex.lsp").attach(client, bufnr)
assert(registration.buf == bufnr and registration.priority == 10)
local get = registration.toggles[1].get
assert(get())
local toggle = vim.fn.maparg(" la", "n", false, true).callback
toggle()
assert(not get(), "State must follow the LSP owner's accepted settings")
accepted = false
toggle()
assert(not get(), "Rejected settings must not change the registered state")
vim.lsp.get_client_by_id = function() end
assert(get() == nil, "A detached client must have unknown state")
vim.lsp.get_client_by_id = get_client
verify()
assert(called == 4)
print("LaTeX forward search passed: focus preference, native mappings and owner build-on-save state")
