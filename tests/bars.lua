-- Real providers may load before or after the bars; drawing never loads them.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = {}, features = { ai = true, tasks = true } })
local dev = require("utils.platform").dev_plugin_root()
local installed = vim.fn.stdpath("data") .. "/lazy/"
for _, path in ipairs({
  dev .. "/ui-tools.nvim",
  dev .. "/lsp-tools.nvim",
  installed .. "overseer.nvim",
  installed .. "copilot.lua",
}) do
  vim.opt.rtp:append(path)
end
vim.o.columns, vim.o.swapfile = 240, false
vim.api.nvim_buf_set_name(0, vim.env.NVIM_TEST_TMP .. "/bar%fixture.txt")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "test_document_symbol", "" })
vim.bo.modified = false
local source = vim.api.nvim_get_current_buf()
local allowed, attempted = {}, {}
local original_require = require
_G.require = function(name)
  for _, prefix in ipairs({ "overseer", "copilot", "lsp-tools", "lualine", "dap", "catppuccin" }) do
    if (name == prefix or name:sub(1, #prefix + 1) == prefix .. ".") and not allowed[prefix] then
      attempted[#attempted + 1] = name
      error("Bar loaded a lazy provider: " .. name)
    end
  end
  return original_require(name)
end
local symbol_calls, symbol_callback = 0, nil
local original_clients, original_client, original_attached =
  vim.lsp.get_clients, vim.lsp.get_client_by_id, vim.lsp.buf_is_attached
local client = { id = 98765, name = "fixture-ls", offset_encoding = "utf-8" }
function client:request(method, _, callback)
  assert(method == "textDocument/documentSymbol")
  symbol_calls, symbol_callback = symbol_calls + 1, callback
  return true, symbol_calls
end
function client:cancel_request() end
local function providers()
  allowed.overseer, allowed["lsp-tools"] = true, true
  require("overseer").setup({ dap = false })
  vim.lsp.get_clients = function(opts)
    return opts and opts.bufnr == source and { client } or original_clients(opts)
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
if vim.env.BARS_TEST == "before" then
  providers()
end
local bars, status = require("features.bars"), require("ui_tools.statusline")
require("ui_tools").setup({ statusline = { globalstatus = true, sections = bars.sections() } })
bars.setup()
local function settle()
  vim.wait(100)
end
local function line()
  return vim.api.nvim_eval_statusline(vim.wo.statusline, { winid = 0, maxwidth = 240 }).str
end
local function winbar()
  return vim.api.nvim_eval_statusline(vim.wo.winbar, { winid = 0, use_winbar = true, maxwidth = 240 }).str
end
assert(line():find("bar%fixture.txt", 1, true), line() .. " width=" .. vim.api.nvim_win_get_width(0))
assert(winbar():find("bar%fixture.txt", 1, true))
if vim.env.BARS_TEST ~= "before" then
  assert(not package.loaded.overseer and not package.loaded["lsp-tools"] and not package.loaded.copilot)
  assert(symbol_calls == 0 and #attempted == 0)
  providers()
end
assert(symbol_callback)
vim.api.nvim_exec_autocmds("LspAttach", { buffer = source, data = { client_id = client.id } })
vim.wait(250)
symbol_callback(nil, {
  {
    name = "test_document_symbol",
    kind = 12,
    range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 20 } },
  },
})
settle()
assert(winbar():find("test_document_symbol", 1, true), winbar())
assert(winbar():find("fixture-ls", 1, true), winbar())
local tasks, fixtures = require("overseer.task_list"), {}
local scans, list_tasks = 0, tasks.list_tasks
tasks.list_tasks = function(opts)
  scans = scans + 1
  return list_tasks(opts)
end
for i, state in ipairs({ "FAILURE", "CANCELED", "SUCCESS", "RUNNING", "RUNNING", "PENDING" }) do
  local task = {
    id = i,
    name = "task" .. i,
    status = state,
    is_disposed = function()
      return false
    end,
    is_running = function(self)
      return self.status == "RUNNING"
    end,
  }
  if i == 1 then
    task.ephemeral = true
  end
  if i == 3 then
    task.source = "jobstart"
  end
  fixtures[#fixtures + 1] = task
  tasks.touch(task)
end
settle()
assert(scans == 1, "Task bursts must share one snapshot: " .. scans)
assert(line():find("󰑮 2", 1, true) and line():find("󰅚 1", 1, true), line())
assert(not line():find("󰄴", 1, true), "Wrapped tasks must stay excluded")
local calls = symbol_calls
for _ = 1, 50 do
  status.update()
  line()
  winbar()
end
settle()
assert(scans == 1 and symbol_calls == calls, "Redraw/cursor updates queried providers")

-- Native Copilot notifications update text without starting its server.
allowed.copilot = true
local copilot, notification = require("copilot.client"), require("copilot.status")
local disabled, attached = copilot.is_disabled, copilot.buf_is_attached
copilot.is_disabled, copilot.buf_is_attached = function()
  return false
end, function()
  return true
end
vim.api.nvim_exec_autocmds("User", { pattern = "LazyLoad", data = "copilot.lua" })
settle()
notification.handlers.statusNotification(nil, { status = "InProgress" }, { client_id = 4321 })
settle()
assert(line():find(" …", 1, true), line())
notification.handlers.statusNotification(nil, { status = "Warning" }, { client_id = 4321 })
settle()
assert(line():find("", 1, true), line())
copilot.is_disabled, copilot.buf_is_attached = disabled, attached
vim.api.nvim_win_set_cursor(0, { 2, 0 })
assert(not winbar():find("test_document_symbol", 1, true), "Stale enclosing symbol")
for _, task in ipairs(fixtures) do
  tasks.remove(task)
end
settle()
assert(not line():find("󰑮", 1, true))
assert(next(status.errors) == nil, vim.inspect(status.errors))
assert(not package.loaded.lualine and not package.loaded.dap and #attempted == 0, vim.inspect(attempted))
require("lsp-tools").setup({
  code_actions = false,
  references = false,
  rename = false,
  outline = false,
  breadcrumbs = false,
})
vim.lsp.get_clients, vim.lsp.get_client_by_id, vim.lsp.buf_is_attached =
  original_clients, original_client, original_attached
_G.require = original_require
print("bars: " .. (vim.env.BARS_TEST or "after") .. " lazy providers, event caches, tasks, Copilot and winbar passed")
