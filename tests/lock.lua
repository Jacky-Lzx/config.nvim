local ok, err = pcall(function()
  local path = vim.fs.joinpath(vim.fn.stdpath("config"), "lazy-lock.json")
  local lock = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  local count = 0
  for name, entry in pairs(lock) do
    local result = vim
      .system({ "git", "-C", vim.fs.joinpath(vim.env.NVIM_TEST_PLUGIN_ROOT, name), "rev-parse", "HEAD" }, { text = true })
      :wait()
    assert(result.code == 0, "Install the locked " .. name .. " checkout before running input checks")
    assert(vim.trim(result.stdout) == entry.commit, "Installed " .. name .. " differs from lazy-lock.json")
    count = count + 1
  end
  io.stdout:write(("Lock checks: %d installed revisions match\n"):format(count))
  io.stdout:flush()
end)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd.cquit(1)
end
vim.cmd.qa({ bang = true })
