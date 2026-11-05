local M = {}
function M.setup()
  if not vim.env.PROF or vim.env.PROF == "" or vim.env.PROF == "0" then
    return
  end
  local path = require("utils.platform").dev_plugin_root() .. "/debug-tools.nvim"
  vim.opt.rtp:append(path)
  require("debug_tools.profiler").startup({ event = "VeryLazy", save = true })
end
return M
