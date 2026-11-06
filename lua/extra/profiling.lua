local M = {}
function M.setup()
  if not vim.env.PROF or vim.env.PROF == "" or vim.env.PROF == "0" then
    return
  end
  local development = require("utils.platform").dev_plugin_root() .. "/debug-tools.nvim"
  local installed = (vim.env.NVIM_PLUGIN_ROOT or (vim.fn.stdpath("data") .. "/plugin-tools")) .. "/debug-tools.nvim"
  local path = vim.uv.fs_stat(development .. "/lua/debug_tools/profiler.lua") and development or installed
  vim.opt.rtp:append(path)
  require("debug_tools.profiler").startup({ event = "ConfigReady", save = true })
end
return M
