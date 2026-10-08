local ok, err = pcall(function()
  local settings = require("config.settings").current()
  local status = require("config.plugins").status()
  if vim.env.NVIM_TEST_MODE == "disabled" then
    assert(not settings.features.input)
    assert(#status.missing == 0)
  else
    assert(settings.features.input)
    assert(#status.missing > 0)
  end
  assert(not status.started)
  assert(not package.loaded.lazy and not package.loaded["blink.cmp"] and not package.loaded.pairs)
  assert(vim.fn.exists(":ConfigPluginsInstall") == 2)
  vim.api.nvim_feedkeys(vim.keycode("i(<CR>x<Esc>"), "xt", false)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "(", "x" }))
  assert(not package.loaded.lazy)
  io.stdout:write("Isolation checks: " .. vim.env.NVIM_TEST_MODE .. " passed\n")
  io.stdout:flush()
end)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd.cquit(1)
end
vim.cmd.qa({ bang = true })
