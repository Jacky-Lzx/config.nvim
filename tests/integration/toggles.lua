local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
vim.g.mapleader = " "
local layout = require("config.toggle_keys")
local leaves, prefixes = {}, {}
for _, group in ipairs(layout.groups()) do
  prefixes[group.prefix] = true
end
for id, entry in pairs(layout.list()) do
  assert(entry.lhs:match("^<leader>t%l%l$"), "Ungrouped toggle: " .. id)
  assert(not leaves[entry.lhs], "Duplicate toggle key: " .. entry.lhs)
  assert(prefixes[entry.lhs:sub(1, -2)], "Missing toggle group: " .. id)
  assert(not prefixes[entry.lhs], "Group prefix is executable: " .. id)
  leaves[entry.lhs] = true
end
local copy = layout.list()
copy.wrap.lhs = "changed"
assert(layout.get("wrap").lhs == "<leader>tew", "Layout snapshots must be independent")
local api = vim.api
local actions = dofile(root .. "/tests/support/actions.lua")
local dev = require("utils.platform").dev_plugin_root()
local installed = vim.fn.stdpath("data") .. "/plugin-tools/"
for _, path in ipairs({
  dev .. "/keymap-tools.nvim",
  dev .. "/pairs.nvim",
  dev .. "/ui-tools.nvim",
  dev .. "/git-tools.nvim",
  installed .. "render-markdown.nvim",
}) do
  vim.opt.runtimepath:append(path)
end
local tools = require("keymap_tools")
local notices, notify = {}, vim.notify
vim.notify = function(message, level, opts)
  notices[#notices + 1] = { message = message, level = level, title = opts and opts.title }
end
local function toggle(key, name, enabled)
  local count = #notices
  vim.fn.maparg(key, "n", false, true).callback()
  assert(#notices == count + 1, "Expected exactly one notification for " .. key)
  assert(
    vim.deep_equal(notices[#notices], {
      message = name .. ": " .. (enabled and "Enabled" or "Disabled"),
      level = vim.log.levels.INFO,
      title = "Toggle",
    }),
    vim.inspect(notices[#notices])
  )
end
local function row(key, opts)
  if key:sub(1, 1) ~= "<" then
    key = "<leader>" .. key
  end
  local rows, info = tools.list(vim.tbl_extend("force", { mode = "n" }, opts or {}))
  assert(#info.errors == 0, vim.inspect(info.errors))
  for _, item in ipairs(rows) do
    if vim.keycode(item.keys) == vim.keycode(key) then
      return item
    end
  end
  error("Missing toggle: " .. key)
end
local diagnostics = require("features.lsp.diagnostics")
diagnostics.setup()
local diagnostic_mapping = vim.fn.maparg("<leader>tld", "n", false, true).callback
require("integrations.diagnostic_toggles").setup()
assert(vim.fn.maparg("<leader>tld", "n", false, true).callback == diagnostic_mapping)
assert(row("tld").toggle.state)
toggle("<leader>tld", "Diagnostics", false)
assert(row("tld").toggle.state == false and row("tld").desc == "Enable Diagnostics")
toggle("<leader>tld", "Diagnostics", true)
toggle("<leader>tll", "Diagnostic virtual lines", true)
toggle("<leader>tll", "Diagnostic virtual lines", false)
toggle("<leader>tlv", "Diagnostic text", false)
toggle("<leader>tlv", "Diagnostic text", true)
local formatter = require("plugins.coding.format-tools")[1]
-- Isolate configuration-owned mappings/metadata from plugin initialization.
local mocked = {
  "format_tools",
  "ui_tools",
  "git_tools",
  "pairs",
  "render-markdown",
  "features.bars",
  "ui_tools.integrations.git_tools",
  "ui_tools.integrations.context_lsp",
}
local function configure(spec)
  local previous = {}
  for _, name in ipairs(mocked) do
    previous[name] = package.loaded[name]
    package.loaded[name] = { setup = function() end, get_state = function() end }
  end
  local ok, err = xpcall(function()
    spec.config({ opts = vim.deepcopy(spec.opts), dir = spec.dir })
  end, debug.traceback)
  for _, name in ipairs(mocked) do
    package.loaded[name] = previous[name]
  end
  assert(ok, err)
end
configure(formatter)
local format_mapping = vim.fn.maparg("<leader>tfa", "n", false, true).callback
assert(row("tfa").toggle.state)
toggle("<leader>tfa", "Auto format", false)
assert(row("tfa").toggle.state == false)
toggle("<leader>tfa", "Auto format", true)

local specs = {
  require("plugins.ui.ui-tools")[1],
  require("plugins.git.git-tools")[1],
  require("plugins.editing.pairs")[1],
  require("languages.markdown.render-markdown")[1],
}
for _, spec in ipairs(specs) do
  configure(spec)
end
local before_inspection = #notices
for _, key in ipairs({ "tpe", "tgb", "tgw", "tgs", "tgo", "tgd", "tmr", "tuz", "tum", "tui", "tud" }) do
  local item = row(key)
  assert(item.toggle and item.toggle.state == nil, "Cold state must remain unknown: " .. key)
  -- Ordinary configured callbacks are executable; inspection remains side-effect free.
end
assert(#notices == before_inspection, "Keymap inspection must remain silent")
for _, name in ipairs({ "pairs", "git_tools", "ui_tools", "render-markdown", "snacks" }) do
  assert(not package.loaded[name], "Status read loaded a feature: " .. name)
end

local adapter = require("features.toggles")
adapter.setup()
assert(vim.fn.maparg("<leader>tld", "n", false, true).callback == diagnostic_mapping)
assert(vim.fn.maparg("<leader>tfa", "n", false, true).callback == format_mapping)
local first = api.nvim_get_current_win()
vim.wo.wrap = true
vim.cmd("vnew")
local second = api.nvim_get_current_win()
vim.wo.wrap = false
assert(row(actions.binding("toggle.wrap").lhs, { win = first }).toggle.state == true)
assert(row(actions.binding("toggle.wrap").lhs, { win = second }).toggle.state == false)
assert(api.nvim_get_current_win() == second)
toggle(actions.binding("toggle.wrap").lhs, "Wrap", true)
assert(vim.wo.wrap and row(actions.binding("toggle.wrap").lhs).desc == "Disable Wrap")
local hidden = api.nvim_create_buf(false, true)
assert(row(actions.binding("toggle.wrap").lhs, { buf = hidden }).toggle.state == nil)
vim.lsp.inlay_hint.enable(true)
toggle("<leader>tlh", "Inlay Hints", false)
assert(row("tlh").toggle.state == false)
local new = api.nvim_create_buf(false, true)
assert(not vim.lsp.inlay_hint.is_enabled({ bufnr = new }), "New buffers must inherit the session toggle")

-- The same action in two buffers has independent mapping ownership.
local scoped = { api.nvim_create_buf(false, true), api.nvim_create_buf(false, true) }
local calls = 0
for _, buf in ipairs(scoped) do
  adapter.map({
    id = "scoped",
    name = "Scoped",
    get = function()
      return true
    end,
    set = function()
      calls = calls + 1
    end,
  }, "<leader>qz", { buffer = buf })
end
for _, buf in ipairs(scoped) do
  api.nvim_buf_call(buf, function()
    local action = actions.binding("toggle.scoped")
    assert(action.entry.buffer == buf)
    vim.fn.maparg(action.lhs, "n", false, true).callback()
    assert(row("qz").toggle.name == "Scoped")
  end)
end
assert(calls == 2, "Registering a second buffer removed the first buffer's toggle")
for _, buf in ipairs(scoped) do
  api.nvim_buf_delete(buf, { force = true })
end

-- An explicit action may initialize a cold owner; reading its metadata cannot.
local initialized, invoked = false, 0
local action = adapter.map({
  id = "cold_action",
  name = "Cold action",
  scope = "buffer",
  get = function(ctx)
    assert(ctx.buf == api.nvim_get_current_buf())
    if initialized then
      return false
    end
  end,
  action = function(ctx)
    assert(ctx.buf == api.nvim_get_current_buf())
    initialized, invoked = true, invoked + 1
  end,
}, "<leader>qa")
assert(row("qa").toggle.state == nil and invoked == 0)
local returned = vim.fn.maparg("<leader>qa", "n", false, true).callback()
assert(returned == false and row("qa").toggle.state == false and invoked == 1)
action:dispose()

-- Same descriptions cannot confuse explicit owner registration.
for i, enabled in ipairs({ true, false }) do
  adapter.map({
    id = "same_name_" .. i,
    name = "Same name",
    get = function()
      return enabled
    end,
    set = function()
      error("query called setter")
    end,
  }, "<leader>q" .. i, { desc = "Custom mapping text" })
end
assert(row("q1").toggle.state == true and row("q2").toggle.state == false)
before_inspection = #notices
local broken = adapter.map({
  id = "broken",
  name = "Broken",
  get = function()
    error("owner unavailable")
  end,
  set = function() end,
}, "<leader>qe")
local items, info = tools.list({ mode = "n" })
assert(#info.errors == 1 and info.errors[1].field == "get")
for _, item in ipairs(items) do
  if item.keys == "<Space>qe" then
    assert(item.desc == "Toggle Broken" and item.toggle.state == nil)
  end
end
assert(#notices == before_inspection, "Status errors must not generate notifications")
vim.fn.maparg("<leader>qe", "n", false, true).callback()
assert(#notices == before_inspection + 1 and notices[#notices].level == vim.log.levels.ERROR)
assert(notices[#notices].message:find("owner unavailable", 1, true))
broken:dispose()

-- Read back the actual result even when the owner refuses the requested state.
local unchanged = adapter.map({
  id = "unchanged",
  name = "Unchanged",
  get = function()
    return true
  end,
  set = function() end,
}, "<leader>qu")
toggle("<leader>qu", "Unchanged", true)
unchanged:dispose()

local pairs = require("pairs")
pairs.setup({})
assert(row("tpe").toggle.state)
toggle("<leader>tpe", "Pairing", false)
assert(row("tpe").toggle.state == false)
toggle("<leader>tpe", "Pairing", true)
local git = require("git_tools")
for _, setting in ipairs({ { "tgb", "line_blame" }, { "tgw", "word_diff" }, { "tgs", "signs" } }) do
  git.toggle(setting[2], true)
  assert(row(setting[1]).toggle.state == true)
  local label = ({ tgb = "Git line blame", tgw = "Git word diff", tgs = "Git signs" })[setting[1]]
  toggle("<leader>" .. setting[1], label, false)
  assert(row(setting[1]).toggle.state == false)
end
assert(row("tgd", { buf = hidden }).toggle.state == nil, "Hidden buffers have no Git comparison tab scope")
local ui = require("ui_tools")
ui.setup({ indent = {}, focus = {} })
assert(row("tui").toggle.state and not row("tud").toggle.state)
toggle("<leader>tui", "Indent guides", false)
assert(row("tui").toggle.state == false)
toggle("<leader>tud", "Scope dimming", true)
assert(row("tud").toggle.state)
toggle("<leader>tud", "Scope dimming", false)
toggle("<leader>tuz", "Zen Mode", true)
assert(row("tuz").toggle.state and not row("tum").toggle.state)
toggle("<leader>tuz", "Zen Mode", false)
assert(not row("tuz").toggle.state)
toggle("<leader>tum", "Zoom", true)
assert(row("tum").toggle.state and not row("tuz").toggle.state)
toggle("<leader>tum", "Zoom", false)
local custom_scroll = function() end
vim.keymap.set("n", "<C-u>", custom_scroll)
toggle("<leader>tus", "Scroll animation", true)
assert(vim.fn.maparg("<C-d>", "n", false, true).callback)
assert(vim.fn.maparg("<C-u>", "n", false, true).callback == custom_scroll)
toggle("<leader>tus", "Scroll animation", false)
assert(vim.fn.maparg("<C-d>", "n") == "")
assert(vim.fn.maparg("<C-u>", "n", false, true).callback == custom_scroll)
vim.keymap.del("n", "<C-u>")
ui.disable()
local render = specs[4]
render.config({ opts = render.opts, dir = render.dir })
assert(row("tmr").toggle.state == false)
toggle("<leader>tmr", "Render Markdown", true)
assert(row("tmr").toggle.state == true)
toggle("<leader>tmr", "Render Markdown", false)
assert(row("tmr").toggle.state == false)
vim.notify = notify
print(
  "PASS configured toggle owners, cold loading, native mappings, cross-window state, session hints, explicit native owner identity, failures, UI/Git/pairs/Markdown"
)
