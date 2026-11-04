local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(require("utils.platform").dev_plugin_root() .. "/task-tools.nvim")
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/auto-session")
require("config.context").initialize({ profiles = {}, features = { tasks = true, sessions = true } })
local integration, tasks = require("features.tasks"), require("task_tools")
tasks.setup({ open = false })
local dir = assert(vim.env.NVIM_TEST_TMP) .. "/task-session"
vim.fn.mkdir(dir, "p")
vim.fn.writefile({ "saved" }, dir .. "/file.txt")
vim.cmd.edit(dir .. "/file.txt")
local original_options = vim.o.sessionoptions
local spec = require("plugins.sessions.auto-session")[1]
spec.init()
local opts = vim.deepcopy(spec.opts)
opts.root_dir, opts.auto_save, opts.auto_restore = dir .. "/sessions/", false, false
opts.session_lens = { session_control = { control_dir = dir .. "/control/" } }
local session = require("auto-session")
session.setup(opts)
local id = assert(tasks.run({ name = "saved build", cmd = { "printf", "saved task" }, cwd = dir }))
assert(vim.wait(2000, function()
  return tasks.get(id).status == "success"
end))
local watch = assert(tasks.run({ name = "saved watcher", cmd = { "printf", "watched task" }, cwd = dir, watch = true }))
assert(vim.wait(2000, function()
  return tasks.get(watch).status == "success"
end))
tasks.open()
assert(session.save_session("task-fixture"), "save real session")
assert(vim.bo.filetype ~= "tasktools", "task panel closed before save")
local bundle = integration.session_path("task-fixture")
assert(vim.uv.fs_stat(bundle), "task definitions saved beside session")
tasks.toggle_watch(watch)
local before = #tasks.list()
assert(session.restore_session("task-fixture"), "restore real session")
assert(#tasks.list() == before, "restore must not execute tasks")
local definitions = tasks.discover({ cwd = dir })
assert(
  vim.iter(definitions):any(function(def)
    return def.name == "saved build"
  end),
  "restored definition available"
)
assert(
  vim.iter(definitions):any(function(def)
    return def.name == "saved watcher" and def.watch == true
  end),
  "watch definition restored"
)
assert(tasks.status().watch == 0, "restoring a watched definition must not register an active watcher")
session.delete_session("task-fixture")
assert(not vim.uv.fs_stat(bundle), "session deletion cleans task definitions")
local context = require("config.context")
local current = context.current
context.current = function()
  return { selection = { features = {} } }
end
local module = package.loaded.task_tools
package.loaded.task_tools = nil
integration.save_session("disabled")
integration.restore_session("disabled")
assert(not package.loaded.task_tools, "disabled tasks stay lazy")
package.loaded.task_tools = module
context.current = current
vim.o.sessionoptions = original_options
print("tasks sessions: actual save/restore/delete passed without autostart")
