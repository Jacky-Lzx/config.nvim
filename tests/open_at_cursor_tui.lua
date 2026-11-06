local directory = assert(vim.env.NVIM_TEST_TMP)
local log = assert(vim.env.NVIM_TEST_OPEN_LOG)
local cases = {
  { lines = { "https://example.com/a" }, keys = "gg0go", target = "https://example.com/a" },
  { lines = { "xx a file.pdf" }, keys = "gg03lv$go", target = directory .. "/a file.pdf" },
  {
    lines = { "literal $HOME `echo BAD` $(echo BAD) % # [中].pdf" },
    keys = "gg0Vgo",
    target = directory .. "/literal $HOME `echo BAD` $(echo BAD) % # [中].pdf",
  },
  { lines = { "xx hello zz", "yy world zz" }, keys = "gg03l\22j4lgo", target = directory .. "/hello\nworld" },
  { lines = { "xx hello zz" }, keys = "gg03lv5lgo", selection = "exclusive", target = directory .. "/hello" },
  { lines = { "https://example.com/after-visual" }, keys = "gg0go", target = "https://example.com/after-visual" },
}
local index, ticks, timer = 0, 0, vim.uv.new_timer()
local function finish(ok, err)
  timer:stop()
  timer:close()
  vim.fn.writefile(
    { ok and "Configured go PTY: Normal, Visual, blockwise, exclusive, literal argv and repeat passed" or err },
    directory .. "/open-result"
  )
  vim.cmd(ok and "qa!" or "cquit 1")
end
local function advance()
  index = index + 1
  local case = cases[index]
  if not case then
    assert(not package.loaded["file_tools.tree"], "Path opens loaded the file tree")
    return finish(true)
  end
  vim.cmd.enew({ bang = true })
  vim.o.selection = case.selection or "inclusive"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, case.lines)
  vim.fn.writefile({ tostring(index), vim.json.encode(case.keys) }, directory .. "/open-stage")
end
vim.api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    vim.cmd.cd(vim.fn.fnameescape(directory))
    advance()
    timer:start(
      20,
      20,
      vim.schedule_wrap(function()
        local ok, err = xpcall(function()
          ticks = ticks + 1
          assert(ticks < 800, "Timed out waiting for opener at case " .. index)
          if vim.fn.filereadable(log) == 0 then
            return
          end
          local entries = vim.fn.readfile(log)
          if #entries < index then
            return
          end
          assert(#entries == index, "Duplicate opener invocation")
          assert(vim.deep_equal(vim.json.decode(entries[index]), { cases[index].target }), entries[index])
          assert(vim.api.nvim_get_mode().mode == "n", "Visual mode was not cleared")
          advance()
        end, debug.traceback)
        if not ok then
          finish(false, err)
        end
      end)
    )
  end,
})
