local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
dofile(root .. "/tests/toolchain_sessions.lua")
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
dofile(root .. "/tests/native_plugins.lua")
local plugins = require("config.plugins").nodes()
assert(not plugins["tiny-code-action.nvim"], "Old code action plugin remains configured")
assert(not plugins["code-actions.nvim"], "Standalone code-actions.nvim remains configured")
assert(not plugins["outline.nvim"], "Standalone outline.nvim remains configured")
assert(not plugins["nvim-lightbulb"], "Standalone lightbulb remains configured")
assert(not plugins["trouble.nvim"], "Trouble must be replaced by LSP tools")
local spec = plugins["lsp-tools.nvim"]
assert(spec and spec.source == "Jacky-Lzx/lsp-tools.nvim")
assert(spec.package.source == require("config.plugins").manager.options.url_format:format(spec.source))
local dev_directory = require("utils.platform").dev_plugin_root() .. "/lsp-tools.nvim"
local expected_directory
if vim.uv.fs_stat(dev_directory) then
  expected_directory = dev_directory
  assert(spec.dev and not spec.package.managed, "Existing local project must load in development mode")
else
  expected_directory = vim.fn.stdpath("data") .. "/plugin-tools/lsp-tools.nvim"
  assert(not not spec.package.managed, "Absent local project must fall back to the GitHub checkout")
end
assert(spec.dir == expected_directory, "Plugin resolved the wrong development/fallback directory")
assert(spec.dependencies["nvim-lspconfig"] ~= nil, "LSP tools must declare its server config provider")
assert(not plugins["nvim-lspconfig"].config, "Config provider must not enable servers separately")
if vim.env.NVIM_TEST_LINK_FIRST == "1" then
  local opener = require("file_tools")
  local original_open, fallback_calls = opener.open_at_cursor, 0
  opener.open_at_cursor = function()
    fallback_calls = fallback_calls + 1
  end
  vim.api.nvim_feedkeys(vim.keycode("go"), "xt", false)
  assert(
    require("config.plugins").initialized(spec.id) and fallback_calls == 1,
    "Path fallback without an LSP must not load the plugin"
  )
  assert(#vim.lsp.get_clients() == 0, "Path fallback started an LSP client")
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
  assert(require("config.plugins").initialized(spec.id), "Reference mapping did not load lsp-tools")
  assert(vim.api.nvim_win_get_cursor(0)[2] == 8, "Lazy reference replay lost the count")
end
if vim.env.NVIM_TEST_OUTLINE_FIRST == "1" then
  -- Exercise first-use outline loading before any LspAttach.
  vim.api.nvim_feedkeys(vim.keycode(vim.g.mapleader .. "go"), "xt", false)
  assert(require("config.plugins").initialized(spec.id), "Outline key did not load lsp-tools")
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
assert(require("config.plugins").initialized(spec.id), "First code action key did not load the local project")
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
local opts = vim.deepcopy((spec).opts)
assert(opts.linked_editing == true, "Linked editing must be owned by LSP tools")
assert(opts.lightbulb == true, "LSP tools indicator must be enabled")
assert(opts.outline.width == 0.15 and not opts.outline.focus_on_open, "Outline layout changed")
assert(opts.outline.icons.Key.icon == "󰌆" and opts.outline.icons.Event.icon == "󱐋", "Outline icons changed")
assert(opts.rename.input == nil, "Rename must use lsp-tools' automatic general input API")
assert(require("input-tools").is_enabled(), "General input renderer must be enabled")
assert(opts.rename.backend == "native", "Rename must use the native diff backend")
assert(vim.deep_equal(opts.rename.native, opts.code_actions.native), "Rename/code action diff styles differ")
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
local diagnostic_ns = vim.api.nvim_create_namespace("ConfiguredDiagnosticFloat")
local source_win, source_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
local layout = vim.fn.winlayout()
vim.diagnostic.set(diagnostic_ns, source_buf, {
  { lnum = 0, col = 0, end_col = 3, message = "Diagnostic at cursor", severity = vim.diagnostic.severity.ERROR },
})
vim.api.nvim_win_set_cursor(source_win, { 1, 0 })
feed("<leader>d")
local float
for _, win in ipairs(vim.api.nvim_list_wins()) do
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
    if table.concat(lines, "\n"):find("Diagnostic at cursor", 1, true) then
      float = win
    end
  end
end
assert(float, "Space d must show the diagnostic in a floating window")
assert(vim.api.nvim_get_current_win() == source_win, "Diagnostic float must preserve editing focus")
assert(vim.api.nvim_get_current_buf() == source_buf, "Diagnostic float must preserve the source buffer")
assert(vim.deep_equal(layout, vim.fn.winlayout()), "Space d must preserve the split layout")
assert(not require("lsp-tools.panel").get("diagnostics"), "Space d must not open the persistent panel")
feed("<leader>d")
assert(vim.api.nvim_get_current_win() == float, "Second Space d must enter the existing diagnostic float")
assert(vim.deep_equal(layout, vim.fn.winlayout()), "Entering the float must preserve the split layout")
vim.api.nvim_win_close(float, true)
assert(vim.api.nvim_get_current_win() == source_win, "Closing the float must restore editing focus")
vim.diagnostic.reset(diagnostic_ns, source_buf)
feed("<leader>d")
assert(vim.deep_equal(layout, vim.fn.winlayout()), "Space d without diagnostics must preserve the layout")
for _, binding in ipairs({
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
local old_references, references_calls = tools.lsp_references, 0
tools.lsp_references = function()
  references_calls = references_calls + 1
end
feed("gi")
feed("<leader>gr")
assert(references_calls == 2, "Reference entry points must use the same picker")
tools.lsp_references = old_references

for _, binding in ipairs({
  { "gd", "lsp_definitions" },
  { "gD", "lsp_declarations" },
  { "gI", "lsp_implementations" },
  { "gy", "lsp_type_definitions" },
  { "<leader>gt", "lsp_type_definitions" },
  { "<leader>ss", "lsp_symbols" },
  { "<leader>sS", "lsp_workspace_symbols" },
  { "<leader>sd", "pick_diagnostics", "all" },
  { "<leader>sD", "pick_diagnostics", "buffer" },
}) do
  local old, invoked = tools[binding[2]], 0
  tools[binding[2]] = function(options)
    invoked = invoked + 1
    if binding[3] then
      assert(((options or {}).scope or "all") == binding[3], "Diagnostic picker scope changed")
    end
  end
  feed(binding[1])
  assert(invoked == 1, binding[1] .. " must reach lsp-tools " .. binding[2])
  tools[binding[2]] = old
end
assert(opts.pickers == true, "Search pickers must be enabled")

assert(opts.code_actions.backend == "native", "Code actions must use the native diff backend")
assert(opts.code_actions.native.file_header == false, "Native previews must omit redundant file headers")

print(
  "lsp_tools: "
    .. ((not spec.package.managed) and "dev" or "GitHub fallback")
    .. ", Lazy code action/reference replay, counts and native mappings passed"
)
vim.cmd("qa!")
