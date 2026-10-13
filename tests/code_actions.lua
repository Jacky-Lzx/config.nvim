local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
local plugins = require("lazy.core.config").plugins
assert(not plugins["tiny-code-action.nvim"], "Old code action plugin remains configured")
local spec = plugins["code-actions.nvim"]
assert(spec and spec.url == "https://github.com/Jacky-Lzx/code-actions.nvim.git")
local dev_directory = require("utils.platform").dev_plugin_root() .. "/code-actions.nvim"
local expected_directory
if vim.uv.fs_stat(dev_directory) then
  expected_directory = dev_directory
  assert(spec.dev and spec._.is_local, "Existing local project must load in development mode")
else
  expected_directory = vim.fn.stdpath("data") .. "/lazy/code-actions.nvim"
  assert(not spec._.is_local, "Absent local project must fall back to the GitHub checkout")
end
assert(spec.dir == expected_directory, "Plugin resolved the wrong development/fallback directory")
local calls = 0
vim.lsp.buf.code_action = function()
  calls = calls + 1
end
-- Exercise Lazy's first-key loading and replay, then the installed callback.
local keys = vim.api.nvim_replace_termcodes(vim.g.mapleader .. "a", true, true, true)
vim.api.nvim_feedkeys(keys, "xt", false)
assert(spec._.loaded, "First code action key did not load the local project")
assert(
  debug.getinfo(require("code_actions").code_action).source:find(expected_directory, 1, true),
  "Loaded module must come from the resolved plugin checkout"
)
assert(calls == 1, "First key must reach the native code action once")
vim.api.nvim_feedkeys(keys, "xt", false)
assert(calls == 2, "Subsequent code action key did not reach native LSP")
assert(vim.fn.maparg("<A-a>", "i", false, true).callback, "Insert mapping missing")
assert(vim.fn.maparg(vim.g.mapleader .. "a", "x", false, true).callback, "Visual mapping missing")
local source = debug.getinfo(vim.ui.select).source
assert(source:find("code_actions/init.lua", 1, true), "Code action selection adapter was not installed")
print(
  "code_actions: " .. (spec._.is_local and "dev" or "GitHub fallback") .. ", Lazy key replay and native mappings passed"
)
vim.cmd("qa!")
