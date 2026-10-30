local M = {}

function M.directory()
  return require("utils.platform").dev_plugin_root() .. "/notification-tools.nvim"
end

function M.available()
  return vim.uv.fs_stat(M.directory() .. "/lua/notification-tools/init.lua") ~= nil
end

return M
