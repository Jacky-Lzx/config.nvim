local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)

package.loaded["toolchain.resources"] = {
  resolve = function(name, resource)
    assert(name == "vue-language-server" and resource == "server")
    return "/fixture/vue-server"
  end,
}
assert(require("languages.vue.compatibility").server_path() == "/fixture/vue-server")
package.loaded["toolchain.resources"] = nil

local pdf = require("features.tasks").definitions({ filetype = "markdown", file = root .. "/a file.md" })[1]
local pdf_font = vim.env.NVIM_MARKDOWN_PDF_FONT
  or (require("utils.platform").is("macos") and "Heiti SC" or "Noto Sans CJK SC")
assert(pdf.cmd[7] == "CJKmainfont=" .. pdf_font)
local previous_font = vim.env.NVIM_MARKDOWN_PDF_FONT
vim.env.NVIM_MARKDOWN_PDF_FONT = "Fixture CJK Font"
assert(
  require("features.tasks").definitions({ filetype = "markdown", file = root .. "/a file.md" })[1].cmd[7]
    == "CJKmainfont=Fixture CJK Font"
)
vim.env.NVIM_MARKDOWN_PDF_FONT = previous_font
assert(pdf.cmd[4] == root .. "/a file.pdf")

dofile(root .. "/lua/integrations/neovide.lua")
for mode, rhs in pairs({ n = '"+p', x = '"+P', i = "<C-R><C-O>+", c = "<C-R>+" }) do
  assert(vim.fn.maparg("<D-v>", mode) == rhs)
end
assert(vim.fn.maparg("<D-v>", "o") == "")
local paste, getreg = vim.api.nvim_paste, vim.fn.getreg
local pasted
vim.fn.getreg = function(reg)
  assert(reg == "+")
  return "literal\ntext"
end
vim.api.nvim_paste = function(data, crlf, phase)
  assert(data == "literal\ntext" and crlf == false and phase == -1)
  pasted = true
end
vim.fn.maparg("<D-v>", "t", false, true).callback()
assert(pasted)
vim.api.nvim_paste, vim.fn.getreg = paste, getreg

for _, key in ipairs({ "]a", "]A", "[a", "[A" }) do
  vim.keymap.set("n", key, "<Nop>")
end
vim.g.mapleader = " "
require("core.keymaps").setup()
assert(vim.fn.maparg("<Space><Space>", "n") == "", "Pulse mapping belongs to ui-tools")

local navigated
package.loaded.git_tools = {
  nav_hunk = function(direction)
    navigated = direction
  end,
}
-- on_attach also registers unrelated action callbacks.
setmetatable(package.loaded.git_tools, {
  __index = function()
    return function() end
  end,
})
require("plugins.git.git-tools")[1].opts.buffer.on_attach(vim.api.nvim_get_current_buf())
local maps = {}
for key, direction in pairs({ ["]h"] = "next", ["[h"] = "prev", ["]H"] = "last", ["[H"] = "first" }) do
  maps[key] = vim.fn.maparg(key, "n", false, true).callback
  maps[key]()
  assert(navigated == direction)
end
local lines = {}
for i = 1, 30 do
  lines[i] = tostring(i)
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
vim.cmd.diffthis()
vim.cmd.vnew()
lines[1], lines[15], lines[30] = "changed first", "changed middle", "changed last"
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
vim.cmd.diffthis()
vim.cmd.diffupdate()
vim.api.nvim_win_set_cursor(0, { 1, 0 })
maps["]h"]()
assert(vim.fn.line(".") == 15)
maps["]H"]()
assert(vim.fn.line(".") == 30)
maps["[h"]()
assert(vim.fn.line(".") == 15)
maps["[H"]()
assert(vim.fn.line(".") == 1)
print("integrations: all tests passed")
