local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
dofile(root .. "/tests/toolchain_sessions.lua")
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
dofile(root .. "/tests/native_plugins.lua")
local files = require("file_tools")
assert(require("file_tools.config").options.opener == require("utils.platform").open)
assert(not package.loaded["file_tools.tree"], "Opening paths must not load the tree")

-- Exercise the real platform adapter while preventing an external application launch.
vim.env.NVIM_OPEN_CMD = "sh"
local original_jobstart = vim.fn.jobstart
local calls = {}
vim.fn.jobstart = function(command, opts)
  assert(command[1] == vim.fn.exepath("sh") and opts.detach)
  calls[#calls + 1] = { path = command[2], mode = vim.api.nvim_get_mode().mode }
  return 123
end

local count = 0
local function check(name, lines, keys, expected, selection)
  vim.cmd.enew({ bang = true })
  vim.o.selection = selection or "inclusive"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  -- Stale marks must not supply the bounds of the active selection.
  vim.fn.setpos("'<", { 0, 1, 1, 0 })
  vim.fn.setpos("'>", { 0, 1, 1, 0 })
  calls = {}
  vim.api.nvim_feedkeys(vim.keycode(keys .. "go"), "xt", false)
  assert(#calls == 1, name .. ": go must invoke the system opener synchronously")
  expected = vim.fs.joinpath(vim.fn.getcwd(), expected)
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
check("normal cfile", { "see lua/core/keymaps.lua here" }, "gg08l", "lua/core/keymaps.lua")

-- The configured semantic-link fallback delegates to the same file-tools API.
local original_open, fallback_calls = files.open_at_cursor, 0
files.open_at_cursor = function()
  fallback_calls = fallback_calls + 1
end
require("config.plugins").nodes()["lsp-tools.nvim"].opts.links.fallback()
assert(fallback_calls == 1, "LSP link fallback must delegate to file-tools")
files.open_at_cursor = original_open
vim.fn.jobstart = original_jobstart
assert(not package.loaded["file_tools.tree"], "Opening paths loaded the file tree")
print("open_at_cursor: " .. count .. " tests passed")
