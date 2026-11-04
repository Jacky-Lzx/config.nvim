-- UI providers can capture Neovim's default error display; keep failures visible in CI.
local ok, err = xpcall(function()
  dofile(assert(arg[1], "Expected a test script"))
end, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
