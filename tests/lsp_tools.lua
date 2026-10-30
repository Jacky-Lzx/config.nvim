local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
local plugins = require("lazy.core.config").plugins
assert(not plugins["tiny-code-action.nvim"], "Old code action plugin remains configured")
assert(not plugins["code-actions.nvim"], "Standalone code-actions.nvim remains configured")
assert(not plugins["outline.nvim"], "Standalone outline.nvim remains configured")
assert(not plugins["nvim-lightbulb"], "Standalone lightbulb remains configured")
assert(not plugins["trouble.nvim"], "Trouble must be replaced by LSP tools")
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
if vim.env.NVIM_TEST_LINK_FIRST == "1" then
  local opener = require("utils.open")
  local original_open, fallback_calls = opener.open_at_cursor, 0
  opener.open_at_cursor = function()
    fallback_calls = fallback_calls + 1
  end
  vim.api.nvim_feedkeys(vim.keycode("go"), "xt", false)
  assert(not spec._.loaded and fallback_calls == 1, "Path fallback without an LSP must not load the plugin")
  assert(not package.loaded["lsp-tools"], "Path fallback must leave the entry module unloaded")
  opener.open_at_cursor = original_open
end
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
if vim.env.NVIM_TEST_OUTLINE_FIRST == "1" then
  -- Exercise first-use outline loading before any LspAttach.
  vim.api.nvim_feedkeys(vim.keycode(vim.g.mapleader .. "go"), "xt", false)
  assert(spec._.loaded, "Outline key did not load lsp-tools")
  local sidebar
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "lsp-tools-outline" then
      sidebar = win
    end
  end
  assert(sidebar and vim.api.nvim_get_current_win() ~= sidebar, "Outline must open without stealing focus")
  require("lsp-tools").close_outline()
  vim.cmd("OutlineOpen")
  require("lsp-tools").close_outline()
  assert(vim.fn.exists(":Outline") == 2, "Outline command alias is missing")
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
assert(opts.linked_editing == true, "Linked editing must be owned by LSP tools")
assert(opts.lightbulb == true, "LSP tools indicator must be enabled")
assert(opts.outline.width == 0.15 and not opts.outline.focus_on_open, "Outline layout changed")
assert(opts.outline.icons.Key.icon == "󰌆" and opts.outline.icons.Event.icon == "󱐋", "Outline icons changed")
assert(opts.rename.input == nil, "Rename must use lsp-tools' automatic general input API")
assert(require("input-tools").is_enabled(), "General input renderer must be enabled")
assert(opts.rename.backend == "delta", "Rename must use the configured delta backend")
assert(vim.deep_equal(opts.rename.delta.args, opts.code_actions.delta.args), "Rename/code action diff styles differ")
for _, feature in ipairs({ "diagnostics", "hover", "links", "inspect", "hierarchy", "results" }) do
  assert(opts[feature], feature .. " must be enabled")
end
local rename_calls = 0
local original_rename = require("lsp-tools").rename
require("lsp-tools").rename = function()
  rename_calls = rename_calls + 1
end
vim.api.nvim_exec_autocmds("LspAttach", { buffer = 0, data = { client_id = 999999 } })
feed(vim.g.mapleader .. "rn")
assert(rename_calls == 1, "Attached rename mapping must reach lsp-tools once")
require("lsp-tools").rename = original_rename
local tools = require("lsp-tools")
for _, binding in ipairs({
  { "<leader>d", "diagnostic" },
  { "<leader>gd", "diagnostics" },
  { "<leader>gl", "locations" },
  { "<leader>gL", "loclist" },
  { "<leader>gq", "quickfix" },
  { "<leader>gH", "hover" },
  { "<leader>g?", "inspect" },
  { "<leader>gT", "type_hierarchy" },
}) do
  local old, invoked = tools[binding[2]], 0
  tools[binding[2]] = function(options)
    invoked = invoked + 1
    if binding[1]:match("<leader>g[dlLq]$") then
      assert(options.toggle, "Result bindings must preserve toggle behavior")
    end
    if binding[2] == "locations" then
      assert(options.position == "right" and options.focus == false)
    end
  end
  feed(binding[1])
  assert(invoked == 1, binding[1] .. " must reach " .. binding[2])
  tools[binding[2]] = old
end
local old_calls, directions = tools.call_hierarchy, {}
tools.call_hierarchy = function(options)
  directions[#directions + 1] = options.direction
end
feed("gci")
feed("gco")
assert(vim.deep_equal(directions, { "incoming", "outgoing" }), "Call tree bindings must preserve direction")
tools.call_hierarchy = old_calls
local old_get_clients, old_link, semantic_links = vim.lsp.get_clients, tools.open_link, 0
vim.lsp.get_clients = function(query)
  if query.method == "textDocument/documentLink" then
    return { reference_client }
  end
  return old_get_clients(query)
end
tools.open_link = function()
  semantic_links = semantic_links + 1
end
feed("go")
assert(semantic_links == 1, "Semantic provider must still route go to lsp-tools")
vim.lsp.get_clients, tools.open_link = old_get_clients, old_link
local picker = require("snacks").picker
local old_references, references_calls = picker.lsp_references, 0
picker.lsp_references = function()
  references_calls = references_calls + 1
end
feed("gi")
feed("<leader>gr")
assert(references_calls == 2, "Reference entry points must use the same picker")
picker.lsp_references = old_references

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
