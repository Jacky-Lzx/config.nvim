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
  "trouble.nvim",
  "nvim-dap",
  "plenary.nvim",
  "nui.nvim",
}) do
  assert(vim.fn.isdirectory(lazy_root .. "/" .. plugin) == 1, "Missing installed plugin: " .. plugin)
  vim.opt.runtimepath:append(lazy_root .. "/" .. plugin)
end
vim.o.swapfile = false
vim.o.columns = 240
vim.g.actual_curwin = vim.api.nvim_get_current_win()

local allowed = {}
local attempted = {}
local original_require = require
_G.require = function(name)
  for _, prefix in ipairs({ "overseer", "trouble", "dap" }) do
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

local symbol_calls, symbol_gets = 0, 0
local has_symbols = false
local symbol_text = "test_document_symbol"
local function load_providers()
  allowed.overseer, allowed.trouble = true, true
  require("overseer").setup({ dap = false })
  local trouble = require("trouble")
  trouble.setup({})
  local statusline = trouble.statusline
  trouble.statusline = function(opts)
    symbol_calls = symbol_calls + 1
    assert(
      vim.deep_equal(opts, {
        mode = "lsp_document_symbols",
        groups = {},
        title = false,
        filter = { range = true },
        format = "{kind_icon}{symbol.name:Normal}",
      }),
      "Trouble symbol options changed"
    )
    local symbols = statusline(opts)
    assert(type(symbols.has) == "function" and type(symbols.get) == "function")
    -- Exercise the real factory, but supply symbols without a running LSP server.
    symbols.has = function()
      return has_symbols
    end
    symbols.get = function()
      symbol_gets = symbol_gets + 1
      return symbol_text
    end
    return symbols
  end
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
assert(symbols:draw(default_hl, true) == "" and symbol_gets == 0)
has_symbols = true
assert(symbols:draw(default_hl, true):find(symbol_text, 1, true))
assert(lualine.winbar():find(symbol_text, 1, true), "Symbols must appear in the real winbar")
has_symbols = false
assert(symbols:draw(default_hl, true) == "")
for _, task in ipairs(fixtures) do
  task_list.remove(task)
end
assert(tasks:draw(default_hl, true) == "", "No tasks must leave no padding or highlights")
render()
assert(tasks.component == component, "Upstream instance must be reused")
assert(symbol_calls == 1, "Trouble provider must be created once")
assert(setups == 1, "Refresh must not reconfigure lualine")
unloaded("dap")
assert(#attempted == 0, vim.inspect(attempted))
_G.require = original_require
print("lualine_lazy: " .. (vim.env.LUALINE_TEST or "after") .. " passed")
