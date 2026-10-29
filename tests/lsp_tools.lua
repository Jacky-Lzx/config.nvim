local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
local plugins = require("lazy.core.config").plugins
assert(not plugins["tiny-code-action.nvim"], "Old code action plugin remains configured")
assert(not plugins["code-actions.nvim"], "Standalone code-actions.nvim remains configured")
local spec = plugins["lsp-tools.nvim"]
assert(spec and spec.url == "git@github.com:Jacky-Lzx/lsp-tools.nvim.git")
local dev_directory = require("utils.platform").dev_plugin_root() .. "/lsp-tools.nvim"
local expected_directory
if vim.uv.fs_stat(dev_directory) then
  expected_directory = dev_directory
  assert(spec.dev and spec._.is_local, "Existing local project must load in development mode")
else
  expected_directory = vim.fn.stdpath("data") .. "/lazy/lsp-tools.nvim"
  assert(not spec._.is_local, "Absent local project must fall back to the GitHub checkout")
end
assert(spec.dir == expected_directory, "Plugin resolved the wrong development/fallback directory")
-- A deterministic document-highlight client tests the real lazy key replay.
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "foo foo foo" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local reference_client = { offset_encoding = "utf-8" }
function reference_client:request(_, _, callback)
  local items = {}
  for _, col in ipairs({ 0, 4, 8 }) do
    items[#items + 1] = {
      range = {
        start = { line = 0, character = col },
        ["end"] = { line = 0, character = col + 3 },
      },
    }
  end
  callback(nil, items)
  return true, 1
end
function reference_client:cancel_request() end
vim.lsp.get_clients = function(opts)
  return opts.method == "textDocument/documentHighlight" and { reference_client } or {}
end
local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
end
if vim.env.NVIM_TEST_REFERENCE_FIRST == "1" then
  feed("2]r")
  assert(spec._.loaded, "Reference mapping did not load lsp-tools")
  assert(vim.api.nvim_win_get_cursor(0)[2] == 8, "Lazy reference replay lost the count")
end
local calls = 0
vim.lsp.buf.code_action = function()
  calls = calls + 1
end
-- Exercise Lazy's first-key loading and replay, then the installed callback.
local keys = vim.api.nvim_replace_termcodes(vim.g.mapleader .. "a", true, true, true)
vim.api.nvim_feedkeys(keys, "xt", false)
assert(spec._.loaded, "First code action key did not load the local project")
assert(
  debug.getinfo(require("lsp-tools").code_action).source:find(expected_directory, 1, true),
  "Loaded module must come from the resolved plugin checkout"
)
assert(calls == 1, "First key must reach the native code action once")
vim.api.nvim_feedkeys(keys, "xt", false)
assert(calls == 2, "Subsequent code action key did not reach native LSP")
assert(vim.fn.maparg("<A-a>", "i", false, true).callback, "Insert mapping missing")
assert(vim.fn.maparg(vim.g.mapleader .. "a", "x", false, true).callback, "Visual mapping missing")
vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed("2]r")
assert(vim.api.nvim_win_get_cursor(0)[2] == 8, "Counted reference mapping failed")
feed("[r")
assert(vim.api.nvim_win_get_cursor(0)[2] == 4, "Previous reference mapping failed")
assert(vim.fn.maparg("]]", "n") == "" and vim.fn.maparg("[[", "n") == "", "Native section mappings remain overridden")
assert(vim.fn.maparg("]]", "t") == "" and vim.fn.maparg("[[", "t") == "", "Terminal prompt mappings remain overridden")
assert(vim.fn.maparg("]r", "t") == "" and vim.fn.maparg("[r", "t") == "", "Reference keys must only map Normal mode")
assert(not package.loaded["snacks.words"], "Snacks.words must not compete for reference ownership")
local source = debug.getinfo(vim.ui.select).source
assert(source:find("lsp-tools/code_actions/init.lua", 1, true), "Code action selection adapter was not installed")
assert(not package.loaded["code_actions"], "Standalone code_actions module was loaded")
local opts = require("lazy.core.plugin").values(spec, "opts", false)
assert(opts.code_actions.backend == "delta", "Delta backend was lost during migration")
assert(
  vim.deep_equal(opts.code_actions.delta.args, {
    "--file-style=omit",
    "--hunk-header-style=file line-number syntax",
  }),
  "Delta arguments changed during migration"
)
print(
  "lsp_tools: "
    .. (spec._.is_local and "dev" or "GitHub fallback")
    .. ", Lazy code action/reference replay, counts and native mappings passed"
)
vim.cmd("qa!")
