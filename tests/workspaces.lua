local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
local enabled = vim.env.NVIM_WORKSPACE_ENABLED ~= "0"
package.preload["config.selection"] = function()
  return { profiles = {}, features = { sessions = enabled } }
end
dofile(root .. "/tests/setup.lua")
vim.o.loadplugins = true
dofile(root .. "/init.lua")
dofile(root .. "/tests/native_plugins.lua")
local plugins = require("config.plugins").nodes()
assert(not plugins["auto-session"] and not package.loaded["auto-session"])
assert((plugins["workspace-tools.nvim"] ~= nil) == enabled)
local ui = vim.deepcopy((plugins["ui-tools.nvim"]).opts)
local dashboard_restore
for _, key in ipairs(ui.dashboard.keys) do
  if key.key == "s" then
    dashboard_restore = key
  end
end
assert(dashboard_restore and dashboard_restore.action == "WorkspaceRestore")
assert(dashboard_restore.enabled() == enabled)
if enabled then
  local plugin = plugins["workspace-tools.nvim"]
  assert(plugin.dir == require("utils.platform").dev_plugin_root() .. "/workspace-tools.nvim")
  local before = vim.o.sessionoptions
  local dir = assert(vim.env.NVIM_TEST_TMP) .. "/configured-workspace"
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile({ "workspace fixture" }, dir .. "/file.txt")
  vim.api.nvim_set_current_dir(dir)
  vim.cmd.edit(dir .. "/file.txt")
  vim.cmd("WorkspaceSave configured name")
  local workspace = require("workspace_tools")
  assert(require("config.plugins").initialized(plugin.id) and workspace.status().initialized)
  assert(not require("workspace_tools.config").options.auto_save)
  assert(not require("workspace_tools.config").options.auto_restore)
  assert(vim.o.sessionoptions == before, "workspace setup changed global sessionoptions")
  assert(workspace.list()[1].name == "configured name")
  assert(not package.loaded.task_tools, "disabled tasks were loaded by workspace hooks")
  for key, command in pairs({
    pw = "WorkspaceSave",
    ps = "WorkspaceRestore",
    pS = "WorkspaceSearch",
    pD = "WorkspaceDelete",
  }) do
    assert(vim.fn.maparg(" " .. key, "n"):find(command, 1, true), "missing mapping " .. key)
  end
  local entry = workspace.list()[1]
  assert(workspace.restore(entry))
  assert(not package.loaded.task_tools)
  assert(workspace.delete(entry))
else
  assert(not package.loaded.workspace_tools)
  for _, key in ipairs({ "pw", "ps", "pS", "pD" }) do
    assert(vim.fn.maparg(" " .. key, "n") == "", "disabled workspace mapping leaked")
  end
  assert(vim.fn.exists(":WorkspaceSave") == 0)
end
assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
print(
  "PASS configured workspace feature gating, local resolution, lazy commands, dashboard, mappings and disabled tasks ("
    .. tostring(enabled)
    .. ")"
)
vim.cmd("qa!")
