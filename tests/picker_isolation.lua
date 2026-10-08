local ok, err = xpcall(function()
  local status = require("config.plugins").status()
  assert(status.started)
  assert(not package.loaded.snacks and not package.loaded["blink.cmp"])
  if vim.env.NVIM_TEST_MODE == "missing-picker" then
    assert(status.features.input.available and not status.features.picker.available)
    assert(vim.fn.maparg("gd", "n", false, true).desc ~= "[Snacks] Goto definition")
    vim.api.nvim_exec_autocmds("InsertEnter", {})
    assert(package.loaded["blink.cmp"])
    assert(not package.loaded.snacks)
  else
    assert(status.features.picker.available and not status.features.input.available)
    assert(status.features.picker.active and not status.features.input.active)
    assert(vim.fn.maparg("gd", "n", false, true).desc == "[Snacks] Goto definition")
    vim.api.nvim_exec_autocmds("InsertEnter", {})
    assert(not package.loaded["blink.cmp"])
    local restored
    if vim.env.NVIM_TEST_MODE == "missing-input" then
      restored = vim.fs.joinpath(status.root, "LuaSnip")
      assert(vim.fn.rename(vim.env.NVIM_TEST_TMP .. "/LuaSnip", restored) == 0)
      local input = require("config.plugins").status().features.input
      assert(input.available and not input.active)
    end
    if vim.fn.executable("lua-language-server") == 1 then
      vim.cmd.edit(vim.env.NVIM_TEST_TMP .. "/picker-only.lua")
      assert(vim.wait(20000, function()
        local client = vim.lsp.get_clients({ bufnr = 0, name = "lua_ls" })[1]
        return client and client.initialized
      end, 20))
    end
    assert(not package.loaded["blink.cmp"])
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop()
    end
    if restored then
      assert(vim.fn.rename(restored, vim.env.NVIM_TEST_TMP .. "/LuaSnip") == 0)
    end
  end
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
  io.stdout:write("Picker isolation checks: " .. vim.env.NVIM_TEST_MODE .. " passed\n")
  io.stdout:flush()
end, debug.traceback)
if not ok then
  print(err)
  vim.cmd.cquit()
end
vim.cmd.qa({ bang = true })
