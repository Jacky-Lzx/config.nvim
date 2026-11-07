local api = vim.api
local function screen()
  vim.cmd("redraw!")
  local result = {}
  for row = 1, vim.o.lines do
    local line = ""
    for col = 1, vim.o.columns do
      line = line .. vim.fn.screenstring(row, col)
    end
    result[#result + 1] = line
  end
  return table.concat(result, "\n")
end
local function check()
  local guard = require("bigfile_tools")
  assert(vim.bo.filetype == "bigfile" and vim.b.bigfile and vim.b.completion == false)
  assert(vim.b.ui_tools_disable and vim.b.config_treesitter_disabled)
  assert(not vim.treesitter.highlighter.active[api.nvim_get_current_buf()])
  assert(vim.wo.statuscolumn == "" and vim.wo.foldmethod == "manual")
  assert(screen():find("BIGFILE_VISIBLE", 1, true), "Startup large file was not rendered")
  local large = api.nvim_get_current_buf()
  vim.cmd.vsplit()
  assert(vim.wo.statuscolumn == "" and vim.wo.conceallevel == 0)
  vim.cmd("enew!")
  api.nvim_buf_set_lines(0, 0, -1, false, { "NORMAL_VISIBLE" })
  assert(not vim.b.bigfile and vim.b.completion == nil)
  assert(screen():find("NORMAL_VISIBLE", 1, true), "Normal buffer was not rendered")
  assert(guard.release(large))
  assert(vim.bo[large].filetype == "lua" and vim.b[large].completion == nil)
  vim.cmd("only!")
  guard.dispose()
  assert(not guard.info().enabled)
end
api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    vim.schedule(function()
      local ok, err = xpcall(check, debug.traceback)
      vim.fn.writefile(
        { ok and "Bigfile PTY: startup frame, protection, split and normal buffer isolation passed" or err },
        vim.env.NVIM_STARTUP_RESULT
      )
      vim.cmd(ok and "qa!" or "cquit 1")
    end)
  end,
})
