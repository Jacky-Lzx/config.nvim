-- Real providers may load before or after the bars; drawing never loads them.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
require("config.context").initialize({ profiles = {}, features = { ai = true, tasks = true } })
local dev = require("utils.platform").dev_plugin_root()
local installed = vim.fn.stdpath("data") .. "/lazy/"
for _, path in ipairs({
  dev .. "/ui-tools.nvim",
  dev .. "/lsp-tools.nvim",
  dev .. "/task-tools.nvim",
}) do
  vim.opt.rtp:append(path)
end
vim.o.columns, vim.o.swapfile = 240, false
vim.api.nvim_buf_set_name(0, vim.env.NVIM_TEST_TMP .. "/bar%test.txt")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "test_document_symbol", "" })
vim.bo.modified = false
local source = vim.api.nvim_get_current_buf()
local allowed, attempted = {}, {}
local original_require = require
_G.require = function(name)
  for _, prefix in ipairs({ "task_tools", "copilot", "lsp-tools", "lualine", "dap", "catppuccin" }) do
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
  allowed.task_tools, allowed["lsp-tools"] = true, true
  require("task_tools").setup({ open = false })
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
require("ui_tools").setup({
  statusline = { globalstatus = true, sections = bars.sections() },
  winbar = bars.winbar_options(),
})
bars.setup()
assert(require("ui_tools.winbar").enabled)
local function settle()
  vim.wait(100)
end
local function line()
  return vim.api.nvim_eval_statusline(vim.wo.statusline, { winid = 0, maxwidth = 240 }).str
end
local function winbar(win)
  win = win or vim.api.nvim_get_current_win()
  return vim.api.nvim_eval_statusline(vim.wo[win].winbar, { winid = win, use_winbar = true, maxwidth = 240 }).str
end
assert(line():find("bar%test.txt", 1, true), line() .. " width=" .. vim.api.nvim_win_get_width(0))
assert(winbar():find("bar%test.txt", 1, true))
if vim.env.BARS_TEST ~= "before" then
  assert(not package.loaded.task_tools and not package.loaded["lsp-tools"] and not package.loaded.copilot)
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

-- Both splits retain their filename and read breadcrumbs at their own cursor,
-- including when they share the same buffer and only one window has focus.
local source_win = vim.api.nvim_get_current_win()
vim.cmd("vsplit")
local split_win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_cursor(split_win, { 2, 0 })
settle()
assert(winbar(source_win):find("bar%test.txt", 1, true), winbar(source_win))
assert(winbar(source_win):find("test_document_symbol", 1, true), winbar(source_win))
assert(winbar(split_win):find("bar%test.txt", 1, true), winbar(split_win))
assert(not winbar(split_win):find("test_document_symbol", 1, true), winbar(split_win))
vim.api.nvim_set_current_win(source_win)
assert(winbar(split_win):find("bar%test.txt", 1, true), winbar(split_win))
assert(not winbar(split_win):find("test_document_symbol", 1, true), winbar(split_win))
vim.api.nvim_win_close(split_win, false)
settle()
local tasks, fixtures = require("task_tools"), {}
local scans, get_status = 0, tasks.status
tasks.status = function()
  scans = scans + 1
  return get_status()
end
for _, command in ipairs({
  { "sh", "-c", "exit 2" },
  { "sleep", "10" },
  { "printf", "success" },
  { "sleep", "10" },
  { "sleep", "10" },
}) do
  fixtures[#fixtures + 1] = assert(tasks.run({ cmd = command }))
end
tasks.stop(fixtures[2])
settle()
assert(scans == 1, "Task bursts must share one snapshot: " .. scans)
assert(line():find("󰑮 2", 1, true) and line():find("󰅚 1", 1, true), line())
assert(line():find("󰄴 1", 1, true) and line():find(" 1", 1, true), line())
local calls = symbol_calls
for _ = 1, 50 do
  status.update()
  line()
  winbar()
end
settle()
assert(scans == 1 and symbol_calls == calls, "Redraw/cursor updates queried providers")

-- Copilot status belongs to the completion window, not the statusline.
assert(not line():find("", 1, true) and not line():find("", 1, true), line())
assert(not package.loaded["copilot.client"] and not package.loaded["copilot.status"])
vim.api.nvim_win_set_cursor(0, { 2, 0 })
assert(not winbar():find("test_document_symbol", 1, true), "Stale enclosing symbol")
for _, id in ipairs(fixtures) do
  local task = tasks.get(id)
  if task.status == "running" then
    tasks.stop(id)
  end
end
assert(vim.wait(2000, function()
  return tasks.status().running == 0 and tasks.status().stopping == 0
end))
for _, id in ipairs(fixtures) do
  tasks.remove(id)
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
-- Real buffer switches restore native window-local values. Keep the winbar and
-- its cache alive through :edit, :buffer, excluded buffers and inherited splits.
local function check_winbar(name)
  -- Check before yielding: an eventually correct bar can still flash blank.
  assert(vim.wo.winbar:find("ui_tools.winbar", 1, true), "Missing immediate winbar for " .. name)
  assert(winbar():find(name, 1, true), "Missing immediate filename: " .. winbar())
  settle()
  assert(winbar():find(name, 1, true), "Missing settled filename: " .. winbar())
end
local path = vim.env.NVIM_TEST_TMP .. "/second%bar.txt"
vim.fn.writefile({ "second file" }, path)
vim.cmd.edit(vim.fn.fnameescape(path))
check_winbar("second%bar.txt")
local second = vim.api.nvim_get_current_buf()
for _ = 1, 2 do
  vim.api.nvim_set_current_buf(source)
  check_winbar("bar%test.txt")
  vim.api.nvim_set_current_buf(second)
  check_winbar("second%bar.txt")
end
vim.cmd("enew")
check_winbar("[No Name]")
vim.bo.buftype = "nofile"
vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = 0 })
settle()
assert(vim.wo.winbar == "")
vim.api.nvim_set_current_buf(second)
check_winbar("second%bar.txt")
vim.cmd("vsplit")
check_winbar("second%bar.txt")
vim.api.nvim_set_current_buf(source)
check_winbar("bar%test.txt")
vim.cmd("close")
check_winbar("second%bar.txt")

-- Scratch FileType and non-entering float creation run in temporary window
-- contexts. A synchronous redraw there can flush native/inactive editor bars.
local exec, temporary_redraws = vim.api.nvim_exec2, {}
vim.api.nvim_exec2 = function(command, ...)
  if
    command == "redrawstatus"
    and (vim.fn.win_gettype() == "autocmd" or vim.api.nvim_win_get_config(0).relative ~= "")
  then
    temporary_redraws[#temporary_redraws + 1] = debug.traceback()
  end
  return exec(command, ...)
end
local editing_win = vim.api.nvim_get_current_win()
local scratch = vim.api.nvim_create_buf(false, true)
vim.bo[scratch].filetype = "bar-status-fixture"
local float = vim.api.nvim_open_win(scratch, false, {
  relative = "editor",
  row = 2,
  col = 2,
  width = 20,
  height = 1,
  style = "minimal",
})
vim.bo[scratch].filetype = "bar-menu-fixture"
vim.api.nvim_win_close(float, true)
vim.api.nvim_buf_delete(scratch, { force = true })
vim.api.nvim_exec2 = exec
assert(#temporary_redraws == 0, "Bars redrew in temporary windows: " .. table.concat(temporary_redraws, "\n"))
assert(vim.api.nvim_get_current_win() == editing_win)
check_winbar("second%bar.txt")

-- A deliberate clear in the same buffer still transfers ownership. Closing
-- that window drops the block, and a new window may own a winbar again.
vim.cmd("vsplit")
check_winbar("second%bar.txt")
vim.wo.winbar = ""
vim.api.nvim_exec_autocmds("WinEnter", {})
settle()
assert(vim.wo.winbar == "")
vim.cmd("enew")
settle()
assert(vim.wo.winbar == "")
vim.cmd("close")
check_winbar("second%bar.txt")

-- Respect a later custom owner, including a buffer's saved custom winbar.
vim.cmd("vsplit")
check_winbar("second%bar.txt")
vim.wo.winbar = "custom owner"
vim.api.nvim_exec_autocmds("WinEnter", {})
settle()
assert(vim.wo.winbar == "custom owner")
vim.cmd("close")
check_winbar("second%bar.txt")
vim.api.nvim_create_autocmd("BufWinEnter", {
  buffer = source,
  once = true,
  callback = function()
    vim.wo.winbar = "saved custom owner"
  end,
})
vim.api.nvim_set_current_buf(source)
settle()
assert(vim.wo.winbar == "saved custom owner")
print("bars: " .. (vim.env.BARS_TEST or "after") .. " lazy providers, event caches, tasks, Copilot and winbar passed")
