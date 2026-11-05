local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
vim.g.mapleader = " "
local api = vim.api
local dev = require("utils.platform").dev_plugin_root()
local installed = vim.fn.stdpath("data") .. "/lazy/"
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
local function row(key, opts)
  local rows, info = tools.list(vim.tbl_extend("force", { mode = "n" }, opts or {}))
  assert(#info.errors == 0, vim.inspect(info.errors))
  for _, item in ipairs(rows) do
    if item.keys == "<Space>" .. key then
      return item
    end
  end
  error("Missing toggle: " .. key)
end
local diagnostics = require("features.lsp.diagnostics")
diagnostics.setup()
local diagnostic_mapping = vim.fn.maparg("<leader>td", "n", false, true).callback
require("integrations.diagnostic_toggles").setup()
assert(vim.fn.maparg("<leader>td", "n", false, true).callback == diagnostic_mapping)
assert(row("td").toggle.state)
diagnostic_mapping()
assert(row("td").toggle.state == false and row("td").desc == "Enable Diagnostics")
diagnostic_mapping()
local conform = require("plugins.coding.conform")[1]
conform.init()
local format_mapping = vim.fn.maparg("<leader>tf", "n", false, true).callback
assert(row("tf").toggle.state)
format_mapping()
assert(row("tf").toggle.state == false and not package.loaded.conform)

local specs = {
  require("plugins.ui.ui-tools")[1],
  require("plugins.git.git-tools")[1],
  require("plugins.editing.pairs")[3],
  require("languages.markdown.specs.render")[1],
}
for _, spec in ipairs(specs) do
  spec.init()
end
for _, key in ipairs({ "tp", "tgb", "tgw", "tgs", "to", "Dt", "tm", "Z", "z", "tG", "tD" }) do
  local item = row(key)
  assert(item.toggle and item.toggle.state == nil, "Cold state must remain unknown: " .. key)
  assert(not item.executable, "Metadata must not create executable mappings: " .. key)
end
for _, name in ipairs({ "pairs", "git_tools", "ui_tools", "render-markdown", "snacks" }) do
  assert(not package.loaded[name], "Status read loaded a feature: " .. name)
end

local adapter = require("features.toggles")
adapter.setup()
assert(vim.fn.maparg("<leader>td", "n", false, true).callback == diagnostic_mapping)
assert(vim.fn.maparg("<leader>tf", "n", false, true).callback == format_mapping)
local first = api.nvim_get_current_win()
vim.wo.wrap = true
vim.cmd("vnew")
local second = api.nvim_get_current_win()
vim.wo.wrap = false
assert(row("tw", { win = first }).toggle.state == true)
assert(row("tw", { win = second }).toggle.state == false)
assert(api.nvim_get_current_win() == second)
vim.fn.maparg("<leader>tw", "n", false, true).callback()
assert(vim.wo.wrap and row("tw").desc == "Disable Wrap")
local hidden = api.nvim_create_buf(false, true)
assert(row("tw", { buf = hidden }).toggle.state == nil)
vim.lsp.inlay_hint.enable(true)
vim.fn.maparg("<leader>th", "n", false, true).callback()
assert(row("th").toggle.state == false)
local new = api.nvim_create_buf(false, true)
assert(not vim.lsp.inlay_hint.is_enabled({ bufnr = new }), "New buffers must inherit the session toggle")

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
local notices, notify = 0, vim.notify
vim.notify = function()
  notices = notices + 1
end
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
assert(notices == 0, "Status errors must not generate notifications")
vim.notify = notify
broken:dispose()

local pairs = require("pairs")
pairs.setup({})
assert(row("tp").toggle.state)
pairs.toggle()
assert(row("tp").toggle.state == false)
pairs.toggle()
local git = require("git_tools")
for _, setting in ipairs({ { "tgb", "line_blame" }, { "tgw", "word_diff" }, { "tgs", "signs" } }) do
  git.toggle(setting[2], true)
  assert(row(setting[1]).toggle.state == true)
  git.toggle(setting[2], false)
  assert(row(setting[1]).toggle.state == false)
end
local ui = require("ui_tools")
ui.setup({ indent = {}, focus = {} })
assert(row("tG").toggle.state and not row("tD").toggle.state)
ui.toggle("indent")
assert(row("tG").toggle.state == false)
ui.dim(true)
assert(row("tD").toggle.state)
ui.dim(false)
ui.zen()
assert(row("Z").toggle.state and not row("z").toggle.state)
ui.zen()
assert(not row("Z").toggle.state)
ui.zoom()
assert(row("z").toggle.state and not row("Z").toggle.state)
ui.zoom()
ui.disable()
local render = specs[4]
render.config(nil, render.opts)
assert(row("tm").toggle.state == false)
render.keys[1][2]()
assert(row("tm").toggle.state == true)
render.keys[1][2]()
assert(row("tm").toggle.state == false)
print(
  "PASS configured toggle owners, cold loading, native mappings, cross-window state, session hints, explicit native owner identity, failures, UI/Git/pairs/Markdown"
)
