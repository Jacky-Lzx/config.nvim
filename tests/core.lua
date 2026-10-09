local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)
vim.g.mapleader = " "

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), "xt", false)
end

vim.o.textwidth = 120
vim.o.softtabstop = 2
local before = #vim.api.nvim_get_autocmds({})
local options = require("core.options")
local autocmds = require("core.autocmds")
local keymaps = require("core.keymaps")
assert(vim.o.textwidth == 120 and vim.o.softtabstop == 2, "Core imports must not apply options")
assert(#vim.api.nvim_get_autocmds({}) == before, "Core imports must not register autocmds")
assert(vim.fn.maparg("jk", "i") == "", "Core imports must not register mappings")
options.setup()
keymaps.setup()
autocmds.setup()
local count = #vim.api.nvim_get_autocmds({ group = "ConfigCore" })
autocmds.setup()
assert(#vim.api.nvim_get_autocmds({ group = "ConfigCore" }) == count, "Repeated setup duplicated core callbacks")
assert(vim.bo.textwidth == 0 and vim.o.autoread and vim.o.undofile and vim.o.confirm)

-- Tab input follows the buffer's shiftwidth instead of a fixed softtabstop.
for _, width in ipairs({ 2, 4 }) do
  vim.cmd.enew({ bang = true })
  vim.bo.shiftwidth = width
  feed("i<Tab>x<Esc>")
  assert(vim.api.nvim_get_current_line() == string.rep(" ", width) .. "x")
end

-- Toggling wrap is local to the current window.
local origin = vim.api.nvim_get_current_win()
vim.cmd.vnew()
feed("<A-z>")
assert(vim.wo.wrap and not vim.wo[origin].wrap)
vim.cmd.close()

-- FileType must change the event buffer even when another buffer is current.
local current = vim.api.nvim_get_current_buf()
local target = vim.api.nvim_create_buf(true, false)
vim.bo[current].formatoptions = "tcroq"
vim.bo[target].formatoptions = "tcroq"
vim.api.nvim_exec_autocmds("FileType", { group = "ConfigCore", buffer = target })
for _, flag in ipairs({ "c", "r", "o" }) do
  assert(not vim.bo[target].formatoptions:find(flag, 1, true), "FileType retained formatoption " .. flag)
end
for _, flag in ipairs({ "t", "q" }) do
  assert(vim.bo[target].formatoptions:find(flag, 1, true), "FileType removed formatoption " .. flag)
end
assert(vim.bo[current].formatoptions == "tcroq", "FileType changed the wrong buffer")

local checktime = vim.cmd.checktime
local checked
vim.cmd.checktime = function(opts)
  checked = opts.args[1]
end
for _, event in ipairs({ "FocusGained", "BufEnter", "TermClose" }) do
  checked = nil
  vim.api.nvim_exec_autocmds(event, { group = "ConfigCore", buffer = target })
  assert(checked == tostring(target), event .. " must check the event buffer")
end
vim.api.nvim_buf_set_lines(target, 0, -1, false, { "unsaved" })
checked = nil
vim.api.nvim_exec_autocmds("FocusGained", { buffer = target })
assert(checked == nil, "External reload must skip modified buffers")
local special = vim.api.nvim_create_buf(false, true)
vim.api.nvim_exec_autocmds("BufEnter", { buffer = special })
assert(checked == nil, "External reload must skip special buffers")
local getcmdwintype = vim.fn.getcmdwintype
vim.fn.getcmdwintype = function()
  return ":"
end
vim.bo[target].modified = false
vim.api.nvim_exec_autocmds("FocusGained", { buffer = target })
assert(checked == nil, "External reload must skip the command-line window")
vim.fn.getcmdwintype, vim.cmd.checktime = getcmdwintype, checktime

local on_yank = vim.hl.on_yank
local highlighted = false
vim.hl.on_yank = function(opts)
  assert(opts.higroup == "IncSearch" and opts.timeout > 0)
  highlighted = true
end
feed("yy")
assert(highlighted, "Yanking must invoke the core highlight hook")
vim.hl.on_yank = on_yank

-- Real command-line input verifies that only bare Visual writes lose their range.
local directory = assert(vim.env.NVIM_TEST_TMP, "NVIM_TEST_TMP is required")
local path = directory .. "/core-write.txt"
local lines = { "first", "second", "third" }
for _, selection in ipairs({ "gg0vl", "ggVj", "gg0<C-v>jl" }) do
  for _, command in ipairs({ "w", "w!", "write", "write!" }) do
    vim.cmd.edit({ args = { path }, bang = true })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    feed(selection .. ":" .. command .. "<CR>")
    assert(vim.deep_equal(vim.fn.readfile(path), lines), selection .. ":" .. command)
    assert(not vim.bo.modified, "Visual write did not save the entire buffer")
  end
end
feed("ggV:s/first/changed/<CR>")
assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "changed", "second", "third" }))
local exported = directory .. "/core-selection.txt"
feed("ggVj:write " .. vim.fn.fnameescape(exported) .. "<CR>")
assert(vim.deep_equal(vim.fn.readfile(exported), { "changed", "second" }), "Selection export lost its range")
feed(":write<CR>")
assert(vim.deep_equal(vim.fn.readfile(path), { "changed", "second", "third" }))
assert(not package.loaded.lazy and not package.loaded.snacks and not package.loaded.conform)
print("Core setup, buffer/window isolation and Visual write checks passed")
