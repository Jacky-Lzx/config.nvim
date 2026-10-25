-- nvim --clean --headless -i NONE -l tests/latex_forward_startup.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(debug.getinfo(1, "S").source:sub(2))))
vim.opt.runtimepath:prepend(root)
local clients, requests, opened, notices, timers = {}, {}, {}, {}, {}
local original_clients, original_defer = vim.lsp.get_clients, vim.defer_fn
vim.lsp.get_clients = function(filter)
  assert(filter.name == "latex_lsp" and filter.bufnr == vim.api.nvim_get_current_buf())
  return clients
end
vim.defer_fn = function(callback, delay)
  assert(delay == 10000)
  timers[#timers + 1] = callback
end
vim.notify = function(message)
  notices[#notices + 1] = message
end
local forward = require("languages.latex.forward_search")
forward.open = function(result, params)
  opened[#opened + 1] = { result = result, params = params }
end
local client = {
  initialized = true,
  request = function(_, method, params, callback, bufnr)
    requests[#requests + 1] = { method = method, params = params, bufnr = bufnr }
    callback(nil, { locations = {} })
    return true, #requests
  end,
}
local function buffer()
  clients = {}
  vim.cmd.enew()
  vim.api.nvim_buf_set_name(0, "/private/tmp/forward-startup-" .. vim.api.nvim_get_current_buf() .. ".tex")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "章节 test", "second line" })
  vim.api.nvim_win_set_cursor(0, { 1, 6 })
  return vim.api.nvim_get_current_buf()
end
local function attach()
  vim.api.nvim_exec_autocmds("LspAttach", { buffer = 0, data = { client_id = 1 } })
end
local buf = buffer()
forward.request(buf)
assert(#requests == 0 and #timers == 1)
attach() -- An unrelated client must not consume the pending search.
assert(#requests == 0)
vim.api.nvim_win_set_cursor(0, { 2, 0 })
clients = { client }
attach()
assert(#requests == 1 and #opened == 1)
assert(requests[1].bufnr == buf and requests[1].params.command == "latex.forwardSearch")
assert(vim.deep_equal(requests[1].params.arguments[1].position, { line = 0, character = 2 }))
timers[1]()
assert(#notices == 0)
forward.request(buf)
assert(#requests == 2 and requests[2].params.arguments[1].position.line == 1)

buf = buffer()
forward.request(buf)
vim.api.nvim_win_set_cursor(0, { 2, 3 })
forward.request(buf)
assert(#timers == 2, "Repeated early searches installed duplicate waiters")
clients = { client }
attach()
assert(#requests == 3 and requests[3].params.arguments[1].position.line == 1)
assert(requests[3].params.arguments[1].position.character == 3)
attach()
assert(#requests == 3)

buf = buffer()
forward.request(buf)
vim.api.nvim_buf_delete(buf, { force = true })
timers[3]()
assert(#notices == 0, "Closing a buffer did not cancel its pending search")
buf = buffer()
forward.request(buf)
timers[4]()
assert(#notices == 1 and notices[1]:find("did not attach", 1, true))
clients = { client }
attach()
assert(#requests == 3, "A timed out search ran after attachment")
vim.lsp.get_clients, vim.defer_fn = original_clients, original_defer
print("LaTeX startup search passed: early keys, UTF-16, duplicate presses, buffer close and timeout")
