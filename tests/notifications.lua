local root = assert(vim.env.NVIM_CONFIG_ROOT)
-- -l enables script verbosity; match interactive startup when checking saves.
vim.o.verbose = 0
vim.opt.rtp:prepend(root)
dofile(root .. "/tests/toolchain_sessions.lua")
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
dofile(root .. "/tests/native_plugins.lua")
local plugins = require("config.plugins").nodes()
assert(not plugins["snacks.nvim"])
assert(not plugins["fidget.nvim"] and not package.loaded.fidget, "Fidget must be removed")
local plugin = assert(plugins["notification-tools.nvim"])
assert(
  plugin.package.source == "git@github.com:Jacky-Lzx/notification-tools.nvim.git",
  "Use the published SSH repository"
)
local dev_root = require("utils.platform").dev_plugin_root() .. "/notification-tools.nvim"
local local_checkout = vim.uv.fs_stat(dev_root .. "/lua/notification-tools/init.lua") ~= nil
local expected_dir = local_checkout and dev_root
  or (require("config.plugins").manager.graph.root .. "/notification-tools.nvim")
assert(
  vim.fs.normalize(plugin.dir) == vim.fs.normalize(expected_dir),
  "Prefer local development, fall back to installed repository"
)
assert(require("config.plugins").initialized("notification-tools.nvim"), "Notifications must load at startup")
assert(not package.loaded["snacks.notifier"])
local tools = require("notification-tools")
tools.clear_history()
local id = vim.notify("Notification route", "info", { title = "Build", timeout = 0 })
assert(tools.history()[1].id == id and tools.history()[1].title == "Build")
local input_plugin = assert(plugins["input-tools.nvim"])
assert(require("config.plugins").initialized(input_plugin.id), "Command-line UI must load at startup")
assert(not plugins["noice.nvim"] and not package.loaded.noice, "Noice must not own overlapping UI")
local input_root = require("utils.platform").dev_plugin_root() .. "/input-tools.nvim"
local input_local = vim.uv.fs_stat(input_root .. "/lua/input-tools/init.lua") ~= nil
local input_expected = input_local and input_root
  or (require("config.plugins").manager.graph.root .. "/input-tools.nvim")
assert(vim.fs.normalize(input_plugin.dir) == vim.fs.normalize(input_expected))
local input = require("input-tools")
assert(input.status().notifications, "Input renderer must hand native messages to notifications")
vim.api.nvim_echo({ { "Native warning route", "WarningMsg" } }, true, { kind = "wmsg" })
assert(vim.wait(500, function()
  return #tools.history() == 2
end, 10))
assert(tools.history()[2].message == "Native warning route")
assert(tools.history()[2].level == vim.log.levels.WARN)

-- Exercise actual new/overwritten file messages, including native progress kinds.
local before_write = #tools.history()
local save_path = vim.env.NVIM_TEST_TMP .. "/notification-save-" .. vim.uv.os_getpid() .. ".txt"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "notification save filter" })
vim.cmd.write(save_path)
vim.wait(40)
assert(#tools.history() == before_write, "New-file success message must be filtered")
vim.cmd.write({ bang = true })
vim.wait(40)
assert(#tools.history() == before_write, "Overwrite success message must be filtered")
local success = '"main.tex" 370L, 23103B written'
assert(tools.notify(success, "info", { source = "neovim" }) == nil)
assert(tools.notify(success, "error", { source = "neovim" }), "Never filter an error by its text")
assert(tools.notify('"main.tex" 370L, 23103B', "info", { source = "neovim" }), "Keep file-read messages")
assert(tools.notify(success, "info", { source = "compiler" }), "Only filter native save status")

tools.dismiss()
tools.clear_tasks()
local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
end
feed(" n")
assert(vim.wait(500, function()
  return vim.bo.filetype == "notification-tools-history"
end, 10))
feed("q")
feed(" sN")
assert(vim.wait(500, function()
  return vim.bo.filetype == "selection_tools_input"
end, 10))
feed("<Esc>")
tools.notify("Dismiss me", nil, { timeout = 0 })
feed(" un")
assert(vim.wait(500, function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "notification-tools" then
      return false
    end
  end
  return true
end, 10))
io.stdout:write("notifications: startup, ownership, native messages, input-tools and mappings passed\n")
vim.cmd("qa!")
