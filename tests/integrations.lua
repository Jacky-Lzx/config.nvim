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

local cpp = require("overseer.template.user.cpp.run")
for _, name in ipairs({ "first.cpp", "second file.cpp" }) do
  vim.api.nvim_buf_set_name(0, root .. "/" .. name)
  assert(cpp.params().executable.default == "./" .. name:gsub("%.cpp$", ""))
end
local pdf = require("overseer.template.user.convert_md_to_pdf").builder()
assert(pdf.args[6] == "CJKmainfont=华文黑体")

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

package.loaded["util.open"] = { open_at_cursor = function() end }
for _, key in ipairs({ "]a", "]A", "[a", "[A" }) do
  vim.keymap.set("n", key, "<Nop>")
end
dofile(root .. "/lua/config/keymaps.lua")
local defer, cleanup = vim.defer_fn
vim.defer_fn = function(cb)
  cleanup = cb
end
local pulse = vim.fn.maparg("<Space><Space>", "n", false, true).callback
local origin = vim.api.nvim_get_current_win()
pulse()
local id = vim.fn.getmatches()[1].id
vim.cmd.vnew()
vim.fn.matchadd("Visual", "other", 10, id)
cleanup()
assert(#vim.fn.getmatches(origin) == 0)
assert(vim.fn.getmatches()[1].id == id)
vim.fn.clearmatches()
pulse()
vim.cmd.close()
cleanup() -- Closing the origin before the timer fires must be harmless.
vim.defer_fn = defer

local navigated
package.loaded.gitsigns = {
  nav_hunk = function(direction)
    navigated = direction
  end,
}
package.loaded.snacks = {
  toggle = function()
    return { map = function() end }
  end,
}
-- on_attach also registers unrelated action callbacks.
setmetatable(package.loaded.gitsigns, {
  __index = function()
    return function() end
  end,
})
require("plugins.git.gitsigns")[1].opts.on_attach(vim.api.nvim_get_current_buf())
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
