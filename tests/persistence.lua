local ok, err = pcall(function()
  local path = vim.fs.joinpath(vim.env.NVIM_TEST_TMP, "undo.txt")
  vim.cmd.edit(vim.fn.fnameescape(path))
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "after" }))
  vim.cmd.undo({ mods = { silent = true } })
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "before" }))
  io.stdout:write("PASS: undo history survives a separate Neovim process\n")
  io.stdout:flush()
end)

if not ok then
  io.stderr:write("FAIL: persistent undo\n" .. tostring(err) .. "\n")
  vim.cmd.cquit(1)
end

vim.cmd.qa({ bang = true })
