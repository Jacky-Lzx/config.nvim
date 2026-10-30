local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
local plugins = require("lazy.core.config").plugins
local snacks = require("lazy.core.plugin").values(plugins["snacks.nvim"], "opts", false)
assert(not plugins["fidget.nvim"] and not package.loaded.fidget, "Fidget must be removed")
local plugin = assert(plugins["notification-tools.nvim"])
assert(plugin.url == "git@github.com:Jacky-Lzx/notification-tools.nvim.git", "Use the published SSH repository")
local dev_root = require("utils.platform").dev_plugin_root() .. "/notification-tools.nvim"
local local_checkout = vim.uv.fs_stat(dev_root .. "/lua/notification-tools/init.lua") ~= nil
local expected_dir = local_checkout and dev_root
  or (require("lazy.core.config").options.root .. "/notification-tools.nvim")
assert(
  vim.fs.normalize(plugin.dir) == vim.fs.normalize(expected_dir),
  "Prefer local development, fall back to installed repository"
)
assert(plugins["notification-tools.nvim"]._.loaded, "Notifications must load at startup")
assert(not snacks.notifier.enabled and not package.loaded["snacks.notifier"])
local tools = require("notification-tools")
tools.clear_history()
local id = vim.notify("Notification route", "info", { title = "Build", timeout = 0 })
assert(tools.history()[1].id == id and tools.history()[1].title == "Build")
local owner = vim.notify
require("lazy").load({ plugins = { "noice.nvim" } })
-- -l does not fire VimEnter; test the real merged Noice config/backend here.
-- The TUI case covers Noice's actual scheduled setup and UI routing.
require("noice.config").setup(require("lazy.core.plugin").values(plugins["noice.nvim"], "opts", false))
assert(vim.notify == owner, "Noice must leave vim.notify owned by notification-tools")
local noice = require("noice.config").options
assert(not noice.notify.enabled and not noice.lsp.progress.enabled and not noice.lsp.message.enabled)
assert(noice.views.notify.backend == "notification_tools")
-- Exercise the real Noice backend resolution rather than a mock adapter.
local view = assert(require("noice.view").get_view("notify", {}))
local message = require("noice.message")("msg_show", "wmsg", "Noice warning route")
message.level = "warn"
message.opts = { title = "texquill" }
view:push(message, { format = false })
view:show()
assert(tools.history()[2].message == "Noice warning route")
assert(tools.history()[2].level == vim.log.levels.WARN)

local hooks = require("integrations.codecompanion_notifications")
hooks.setup()
hooks.setup()
assert(#vim.api.nvim_get_autocmds({ group = "CodeCompanionNotificationHooks" }) == 2)
local function event(kind, data)
  vim.api.nvim_exec_autocmds("User", { pattern = "CodeCompanionRequest" .. kind, data = data })
end
event("Finished", { id = "unknown", status = "error" })
event("Started", {})
event("Started", { id = 1, adapter = { formatted_name = "Claude", model = "test" } })
event("Started", { id = "1" })
assert(#tools.tasks() == 2, "Concurrent IDs must remain independent")
event("Finished", { id = 1, status = "error" })
event("Finished", { id = "1", status = "success" })
local tasks = tools.tasks()
assert(tasks[1].status == "success" and tasks[2].status == "error")
assert(tasks[2].source == "Claude (test)")
event("Started", { id = 2, adapter = "missing" })
event("Finished", { id = 2, status = "cancelled" })
assert(tools.tasks()[1].status == "cancelled")
event("Started", { id = 3 })
hooks.setup()
assert(tools.tasks()[1].status == "cancelled", "Repeated setup must finish orphaned tasks")
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
feed(" sn")
assert(vim.wait(500, function()
  return vim.bo.filetype == "notification-tools-history"
end, 10))
feed("q")
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
io.stdout:write("notifications: startup, ownership, Noice, CodeCompanion API adapter and mappings passed\n")
vim.cmd("qa!")
