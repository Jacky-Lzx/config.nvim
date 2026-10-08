local utils = dofile(vim.fn.getcwd() .. "/lua/util/open.lua")
local calls = {}
utils.process_open = function(path)
  calls[#calls + 1] = { path = path, mode = vim.api.nvim_get_mode().mode }
end

local synchronous
vim.keymap.set({ "n", "x" }, "<F5>", function()
  local before = #calls
  utils.open_at_cursor()
  synchronous = #calls == before + 1
end)

local count = 0
local function check(name, lines, keys, expected, selection)
  vim.cmd.enew({ bang = true })
  vim.o.selection = selection or "inclusive"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  -- Stale marks must not supply the bounds of the active selection.
  vim.fn.setpos("'<", { 0, 1, 1, 0 })
  vim.fn.setpos("'>", { 0, 1, 1, 0 })
  calls = {}
  synchronous = false
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys .. "<F5>", true, false, true), "xt", false)
  assert(synchronous, name .. ": process_open must run synchronously")
  assert(vim.deep_equal(calls, { { path = expected, mode = "n" } }), name .. ": " .. vim.inspect(calls))
  vim.wait(10, function()
    return false
  end)
  assert(#calls == 1, name .. ": unexpected deferred call")
  count = count + 1
end

check("characterwise", { "xx hello zz" }, "gg03lv4l", "hello")
check("reverse characterwise", { "xx hello zz" }, "gg07lv4h", "hello")
check("exclusive", { "xx hello zz" }, "gg03lv5l", "hello", "exclusive")
check("reverse exclusive", { "xx hello zz" }, "gg08lv5h", "hello", "exclusive")
check("multiline", { "xx hello", "middle", "world zz" }, "gg03lv2j1l", "hello\nmiddle\nworld")
check("linewise", { "xx hello", "world zz" }, "gg03lVj", "xx hello\nworld zz")
check("reverse linewise", { "xx hello", "world zz" }, "G03lVk", "xx hello\nworld zz")
check("exclusive linewise", { "xx hello", "world zz" }, "gg03lVj", "xx hello\nworld zz", "exclusive")
check("blockwise", { "xx hello zz", "yy world zz" }, "gg03l<C-v>j4l", "hello\nworld")
check("reverse blockwise", { "xx hello zz", "yy world zz" }, "G07l<C-v>k4h", "hello\nworld")
check("exclusive blockwise", { "xx hello zz", "yy world zz" }, "gg03l<C-v>j5l", "hello\nworld", "exclusive")
check("reverse exclusive blockwise", { "xx hello zz", "yy world zz" }, "G08l<C-v>k5h", "hello\nworld", "exclusive")
check("short block line", { "xx hello zz", "", "yy world zz" }, "gg03l<C-v>2j4l", "hello\n     \nworld")
check("normal cfile", { "see lua/util/open.lua here" }, "gg08l", "lua/util/open.lua")
print("open_at_cursor: " .. count .. " tests passed")
