-- Run: nvim --headless -u NONE -i NONE --noplugin -l tests/lualine_lazy.lua
-- Also run with LUALINE_TEST=before to load providers before lualine.
local lazy_root = vim.fn.stdpath("data") .. "/lazy"
for _, plugin in ipairs({
  "lualine.nvim",
  "catppuccin",
  "copilot-lualine",
  "copilot.lua",
  "nvim-web-devicons",
  "overseer.nvim",
  "nvim-dap",
  "plenary.nvim",
  "nui.nvim",
}) do
  assert(vim.fn.isdirectory(lazy_root .. "/" .. plugin) == 1, "Missing installed plugin: " .. plugin)
  vim.opt.runtimepath:append(lazy_root .. "/" .. plugin)
end
vim.opt.runtimepath:append(require("utils.platform").dev_plugin_root() .. "/lsp-tools.nvim")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "test_document_symbol", "" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.o.swapfile = false
vim.o.columns = 240
vim.g.actual_curwin = vim.api.nvim_get_current_win()

local allowed = {}
local attempted = {}
local original_require = require
_G.require = function(name)
  for _, prefix in ipairs({ "overseer", "trouble", "dap", "lsp-tools" }) do
    if (name == prefix or name:sub(1, #prefix + 1) == prefix .. ".") and not allowed[prefix] then
      attempted[#attempted + 1] = name
      error("Unexpected lazy dependency: " .. name)
    end
  end
  return original_require(name)
end
local function unloaded(prefix)
  for name in pairs(package.loaded) do
    assert(name ~= prefix and name:sub(1, #prefix + 1) ~= prefix .. ".", "Loaded " .. name)
  end
end

local symbol_calls = 0
local symbol_text = "test_document_symbol"
local symbol_callback
local original_clients = vim.lsp.get_clients
local original_client = vim.lsp.get_client_by_id
local original_attached = vim.lsp.buf_is_attached
local client = { id = 98765, name = "lualine-fixture", offset_encoding = "utf-8" }
function client:request(method, _, callback)
  assert(method == "textDocument/documentSymbol")
  symbol_calls = symbol_calls + 1
  symbol_callback = callback
  return true, symbol_calls
end
function client:cancel_request() end
local function load_providers()
  allowed.overseer, allowed["lsp-tools"] = true, true
  require("overseer").setup({ dap = false })
  vim.lsp.get_clients = function(opts)
    if opts and opts.method == "textDocument/documentSymbol" then
      return { client }
    end
    return original_clients(opts)
  end
  vim.lsp.get_client_by_id = function(id)
    return id == client.id and client or original_client(id)
  end
  vim.lsp.buf_is_attached = function(buf, id)
    return id == client.id or original_attached(buf, id)
  end
  require("lsp-tools").setup({
    code_actions = false,
    references = false,
    rename = false,
    outline = false,
    breadcrumbs = { request_timeout = 10000 },
  })
end

local spec = dofile("lua/plugins/ui/lualine.lua")[1]
assert(
  vim.deep_equal(spec.dependencies, { "nvim-tree/nvim-web-devicons", { "AndreM222/copilot-lualine", enabled = true } })
)
if vim.env.LUALINE_TEST == "before" then
  load_providers()
  assert(not package.loaded.lualine, "Providers should load before lualine")
end

-- Capture the actual instances built by installed lualine, without replacing setup/render.
local loader = require("lualine.utils.loader")
local load_all = loader.load_all
local config
loader.load_all = function(opts)
  load_all(opts)
  config = opts
end
local lualine = require("lualine")
local setup = lualine.setup
local setups = 0
lualine.setup = function(opts)
  setups = setups + 1
  return setup(opts)
end
spec.config(nil, vim.deepcopy(spec.opts))
local tasks = assert(config.sections.lualine_x[1])
local symbols = assert(config.winbar.lualine_b[1])
local default_hl = "%#lualine_x_normal#"
local function render()
  vim.g.actual_curwin = vim.api.nvim_get_current_win()
  lualine.statusline()
  lualine.winbar()
  lualine.refresh({ force = true })
end
render()
if vim.env.LUALINE_TEST ~= "before" then
  assert(tasks:draw(default_hl, true) == "")
  assert(symbols:draw(default_hl, true) == "")
  assert(tasks.component == nil and symbol_calls == 0)
  assert(not package.loaded["lualine.components.overseer"])
  unloaded("overseer")
  unloaded("trouble")
  unloaded("lsp-tools")
  unloaded("dap")
  assert(#attempted == 0, vim.inspect(attempted))
  load_providers()
end

local task_list = require("overseer.task_list")
local fixtures = {}
for i, status in ipairs({ "FAILURE", "CANCELED", "SUCCESS", "RUNNING", "RUNNING", "PENDING" }) do
  local task = {
    id = i,
    name = "task" .. i,
    status = status,
    is_disposed = function()
      return false
    end,
    is_running = function(self)
      return self.status == "RUNNING"
    end,
  }
  fixtures[#fixtures + 1] = task
  task_list.touch(task)
end
-- Default upstream behavior includes ephemeral tasks but excludes wrapped tasks.
fixtures[1].ephemeral = true
fixtures[3].source = "jobstart"
fixtures[3].name = fixtures[1].name
render()
local upstream = require("lualine.components.overseer")
local component = assert(tasks.component)
local function visuals(status)
  -- Lualine gives concurrent component instances distinct highlight group names.
  return (
    status:gsub("%%#(.-)#", function(name)
      return vim.inspect(vim.api.nvim_get_hl(0, { name = name, link = false }))
    end)
  )
end
local expected = upstream(vim.deepcopy(tasks.options))
local actual = tasks:draw(default_hl, true)
local expected_draw = expected:draw(default_hl, true)
assert(visuals(actual) == visuals(expected_draw), "Task visuals differ from upstream")
assert(actual:find("2", 1, true), "Both running tasks must count")
assert(lualine.statusline():find(component.symbols.RUNNING .. "2", 1, true), "Tasks must appear in the real statusline")
assert(not actual:find("SUCCESS", 1, true), "Wrapped task must be excluded")
assert(actual:sub(-#default_hl) == default_hl, "Task color must reset before the macro component")
for _, status in ipairs({ "FAILURE", "CANCELED", "RUNNING" }) do
  local token = component.highlight_groups[status]
  local name = component:format_hl(token):match("%%#(.-)#")
  local color = vim.api.nvim_get_hl(0, { name = name, link = false }).fg
  assert(color == vim.api.nvim_get_hl(0, { name = "Overseer" .. status, link = false }).fg)
end

-- Compare filtering/options and icon fallbacks using the real upstream task list.
local deferred = tasks.options[1]
for _, options in ipairs({
  { status = "RUNNING", icons_enabled = false },
  { include_ephemeral = false, wrapped = true, colored = false, label = "T:" },
  {
    filter = function(task)
      return task.id == 1
    end,
    symbols = { FAILURE = "failed:" },
  },
  { unique = true, wrapped = true, status = { "FAILURE", "SUCCESS" } },
}) do
  local opts = vim.tbl_extend("force", vim.deepcopy(tasks.options), options)
  assert(visuals(deferred(vim.deepcopy(opts)):draw(default_hl, true)) == visuals(upstream(opts):draw(default_hl, true)))
end
assert(symbols:draw(default_hl, true) == "")
assert(symbol_callback, "Breadcrumb provider did not request symbols")
symbol_callback(nil, {
  {
    name = symbol_text,
    kind = 12,
    range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = #symbol_text } },
  },
})
assert(
  vim.wait(1000, function()
    return symbols:draw(default_hl, true):find(symbol_text, 1, true) ~= nil
  end),
  "Real lsp-tools breadcrumbs did not reach lualine"
)
assert(lualine.winbar():find(symbol_text, 1, true), "Symbols must appear in the real winbar")
vim.api.nvim_win_set_cursor(0, { 2, 0 })
assert(symbols:draw(default_hl, true) == "", "Leaving the scope must clear breadcrumbs")

for _, task in ipairs(fixtures) do
  task_list.remove(task)
end
assert(tasks:draw(default_hl, true) == "", "No tasks must leave no padding or highlights")
render()
assert(tasks.component == component, "Upstream instance must be reused")
assert(symbol_calls == 1, "Rendering must reuse the document symbol cache")
assert(setups == 1, "Refresh must not reconfigure lualine")
unloaded("dap")
unloaded("trouble")
require("lsp-tools").setup({
  code_actions = false,
  references = false,
  rename = false,
  outline = false,
  breadcrumbs = false,
})
vim.lsp.get_clients = original_clients
vim.lsp.get_client_by_id = original_client
vim.lsp.buf_is_attached = original_attached
assert(#attempted == 0, vim.inspect(attempted))
_G.require = original_require
print("lualine_lazy: " .. (vim.env.LUALINE_TEST or "after") .. " passed")
