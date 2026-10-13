local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
local plugins = require("lazy.core.config").plugins
assert(not plugins["tiny-code-action.nvim"], "Old code action plugin remains configured")
local spec = plugins["code-actions.nvim"]
if vim.uv.fs_stat(require("utils.platform").dev_plugin_root() .. "/code-actions.nvim") == nil then
  assert(not spec, "Missing unpublished checkout must be disabled")
  assert(vim.fn.maparg("gra", "n", false, true).callback, "Native code action fallback missing")
  print("code_actions: absent local checkout keeps native gra available")
  vim.cmd("qa!")
  return
end
assert(spec and spec.dir == require("utils.platform").dev_plugin_root() .. "/code-actions.nvim")
assert(spec._.is_local, "Local unpublished project must load from its directory")
local calls = 0
vim.lsp.buf.code_action = function()
  calls = calls + 1
end
-- Exercise Lazy's first-key loading and replay, then the installed callback.
local keys = vim.api.nvim_replace_termcodes(vim.g.mapleader .. "a", true, true, true)
vim.api.nvim_feedkeys(keys, "xt", false)
assert(spec._.loaded, "First code action key did not load the local project")
assert(calls == 1, "First key must reach the native code action once")
vim.api.nvim_feedkeys(keys, "xt", false)
assert(calls == 2, "Subsequent code action key did not reach native LSP")
assert(vim.fn.maparg("<A-a>", "i", false, true).callback, "Insert mapping missing")
assert(vim.fn.maparg(vim.g.mapleader .. "a", "x", false, true).callback, "Visual mapping missing")
local source = debug.getinfo(vim.ui.select).source
assert(source:find("code_actions/init.lua", 1, true), "Code action selection adapter was not installed")
print("code_actions: local project, Lazy key replay and native mappings passed")
vim.cmd("qa!")
