local ok, err = xpcall(function()
  assert(not require("config.plugins").status().started)
  assert(not package.loaded.lazy and not package.loaded["blink.cmp"])
  local status = require("features.lsp").status()
  assert(status.enabled and #status.servers == 1)
  assert(vim.fn.exists(":ConfigLspInfo") == 2)
  if vim.env.NVIM_TEST_LSP_MODE == "missing" then
    assert(not status.servers[1].available and not status.servers[1].enabled)
    local warnings = {}
    vim.health.start = function() end
    vim.health.ok = function() end
    vim.health.info = function() end
    vim.health.warn = function(message)
      warnings[#warnings + 1] = message
    end
    require("config.health").check()
    assert(vim.list_contains(warnings, "lua_ls is unavailable"))
    vim.api.nvim_feedkeys(vim.keycode("ihello<Esc>"), "xt", false)
    assert(vim.api.nvim_get_current_line() == "hello")
    io.stdout:write("LSP isolation checks: missing server passed\n")
  else
    assert(status.servers[1].available and status.servers[1].enabled)
    local path = vim.env.NVIM_TEST_TMP .. "/native.lua"
    vim.fn.writefile({ "local value = 42", "print(value)", "print(missing_symbol)" }, path)
    vim.cmd.edit(path)
    assert(
      vim.wait(20000, function()
        local client = vim.lsp.get_clients({ bufnr = 0, name = "lua_ls" })[1]
        return client and client.initialized
      end, 20),
      "Native language server did not attach"
    )
    local client = vim.lsp.get_clients({ bufnr = 0, name = "lua_ls" })[1]
    local hover = assert(client:request_sync("textDocument/hover", {
      textDocument = { uri = vim.uri_from_bufnr(0) },
      position = { line = 1, character = 7 },
    }, 10000, 0))
    assert(not hover.err and hover.result and hover.result.contents)
    assert(vim.wait(20000, function()
      return #vim.diagnostic.get(0) > 0
    end, 20))
    assert(not package.loaded.lazy and not package.loaded["blink.cmp"])
    client:stop()
    assert(vim.wait(5000, function()
      return client:is_stopped()
    end, 20))
    io.stdout:write("LSP isolation checks: native server without input plugins passed\n")
  end
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
  io.stdout:flush()
end, debug.traceback)
if not ok then
  print(err)
  vim.cmd.cquit()
end
vim.cmd.qa({ bang = true })
