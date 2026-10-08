local M = {}
local child = vim.fn.jobstart({
  vim.v.progpath,
  "--headless",
  "--embed",
  "-i",
  "NONE",
  "--cmd",
  "lua dofile(vim.fn.stdpath('config') .. '/tests/setup.lua')",
}, { rpc = true })
assert(child > 0, "Could not start the test editor")
local sequence = 0

function M.remote(code, ...)
  return vim.rpcrequest(child, "nvim_exec_lua", code, { ... })
end

function M.wait(code, timeout)
  local ok = vim.wait(timeout or 10000, function()
    return M.remote(code) == true
  end, 20)
  if not ok then
    print(
      M.remote(
        "return vim.inspect({ mode = vim.fn.mode(), cursor = vim.api.nvim_win_get_cursor(0), file = vim.api.nvim_buf_get_name(0), messages = vim.api.nvim_exec2('messages', {output = true}).output })"
      )
    )
  end
  assert(ok, code)
end

function M.feed(keys)
  sequence = sequence + 1
  local input = keys .. "<Cmd>lua vim.g.config_picker_input=" .. sequence .. "<CR>"
  assert(vim.rpcrequest(child, "nvim_input", input) == #input)
  M.wait("return vim.g.config_picker_input == " .. sequence)
end

function M.run(callback, label)
  local ok, err = xpcall(function()
    M.wait("return vim.fn.exists(':ConfigInfo') == 2")
    M.remote("vim.o.lines = 50; vim.o.columns = 140")
    callback()
    local errors = M.remote("return _G.config_test_errors")
    assert(#errors == 0, table.concat(errors, "\n"))
    io.stdout:write(label .. "\n")
    io.stdout:flush()
  end, debug.traceback)
  pcall(
    M.remote,
    [[
    if package.loaded["snacks.picker"] then
      for _, picker in ipairs(require("snacks").picker.get()) do picker:close() end
    end
    local clients = vim.lsp.get_clients()
    for _, client in ipairs(clients) do client:stop() end
    vim.wait(5000, function()
      for _, client in ipairs(clients) do if not client:is_stopped() then return false end end
      return true
    end, 20)
  ]]
  )
  pcall(vim.rpcnotify, child, "nvim_command", "qa!")
  if vim.fn.jobwait({ child }, 2000)[1] == -1 then
    vim.fn.jobstop(child)
  end
  if not ok then
    print(err)
    vim.cmd.cquit()
  end
  vim.cmd.qa({ bang = true })
end

return M
