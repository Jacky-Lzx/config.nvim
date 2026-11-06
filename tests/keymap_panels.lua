local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
dofile(root .. "/tests/setup.lua")
vim.o.loadplugins = true
dofile(root .. "/init.lua")
dofile(root .. "/tests/native_plugins.lua")
assert(vim.wait(3000, function()
  return vim.g.config_ready
end))
local api, tools = vim.api, require("keymap_tools")
local hints = require("keymap_tools.hints")
local function panel(filetype)
  assert(vim.bo.buftype == "nofile" and vim.bo.filetype == filetype)
  tools.refresh()
  assert(#hints.triggers == 1, filetype .. " should only have the Normal leader trigger")
  local trigger = hints.triggers[1]
  assert(trigger.mode == "n" and trigger.raw == vim.keycode(vim.g.mapleader))
end
require("ui_tools.dashboard").open()
panel("ui_tools_dashboard")
require("ui_tools.dashboard").close()
require("file_tools").open({ root = root })
panel("file-tools")
require("file_tools").close()
require("task_tools.ui").open()
panel("tasktools")
require("task_tools.ui").close()
require("toolchain.ui").open(false)
panel("toolchain")
require("toolchain.ui").dispose()
vim.cmd("PluginTools")
assert(vim.bo.filetype == "plugin-tools")
local select = vim.fn.maparg("<Space>", "n", false, true).callback
assert(type(select) == "function", "PluginTools selection mapping missing")
tools.refresh()
assert(#hints.triggers == 0, "leader hint displaced PluginTools Space selection")
assert(vim.fn.maparg("<Space>", "n", false, true).callback == select)
api.nvim_win_close(api.nvim_get_current_win(), true)
-- Preview buffers may keep a source-code filetype; that must not opt them in.
for _, filetype in ipairs({
  "selection_tools_input",
  "selection_tools_list",
  "input-tools-input",
  "ui-tools-menu",
  "image_tools_preview",
  "lsp-tools-results",
  "lua",
  "markdown",
  "json",
}) do
  local buf = api.nvim_create_buf(false, true)
  api.nvim_set_current_buf(buf)
  vim.cmd("noautocmd setlocal filetype=" .. filetype)
  tools.refresh()
  assert(#hints.triggers == 0, "unexpected automatic hints in " .. filetype)
  api.nvim_buf_delete(buf, { force = true })
end
vim.cmd("enew!")
tools.refresh()
assert(#hints.triggers > 1, "ordinary-buffer prefix hints changed")
assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
io.stdout:write("PASS real panel leader hints and input/preview exclusions\n")
