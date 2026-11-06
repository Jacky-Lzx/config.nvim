local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)

local exepath, resolve, stat = vim.fn.exepath, vim.fn.resolve, vim.uv.fs_stat
vim.fn.exepath = function()
  return "/npm/vue-language-server/bin/vue-language-server"
end
vim.fn.resolve = function(path)
  return path
end
local expected = "/npm/vue-language-server/node_modules/@vue/language-server"
vim.uv.fs_stat = function(path)
  return path == expected and {} or nil
end
assert(require("languages.vue.compatibility").server_path() == expected)
vim.fn.exepath, vim.fn.resolve, vim.uv.fs_stat = exepath, resolve, stat

local pdf = require("features.tasks").definitions({ filetype = "markdown", file = root .. "/a file.md" })[1]
assert(pdf.cmd[7] == "CJKmainfont=华文黑体")
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
