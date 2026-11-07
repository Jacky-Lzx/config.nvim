local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(require("utils.platform").dev_plugin_root() .. "/task-tools.nvim")
vim.opt.rtp:append(require("utils.platform").dev_plugin_root() .. "/workspace-tools.nvim")
require("config.context").initialize({ profiles = {}, features = { tasks = true, sessions = true } })
local integration, tasks = require("features.tasks"), require("task_tools")
tasks.setup({ open = false })
local dir = assert(vim.env.NVIM_TEST_TMP) .. "/task-session"
vim.fn.mkdir(dir, "p")
vim.fn.writefile({ "saved" }, dir .. "/file.txt")
vim.cmd.edit(dir .. "/file.txt")
local original_options = vim.o.sessionoptions
local spec = require("plugins.sessions.workspace-tools")[1]
local opts = vim.deepcopy(spec.opts)
opts.directory, opts.auto_save, opts.auto_restore = dir .. "/workspaces/", false, false
local session = require("workspace_tools")
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
local entry, err = session.save({ name = "task-fixture" })
assert(entry, err)
assert(vim.bo.filetype ~= "tasktools", "task panel closed before save")
local bundle = integration.session_path(entry.id)
assert(vim.uv.fs_stat(bundle), "task definitions saved beside session")
tasks.toggle_watch(watch)
local before = #tasks.list()
assert(session.restore(entry), "restore real session")
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
assert(session.delete(entry))
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
print("workspace task hooks: actual save/restore/delete passed without autostart")
