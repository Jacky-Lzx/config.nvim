local M = {}

function M.available()
  local path = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "nvim-web-devicons", "lua/nvim-web-devicons.lua")
  return vim.fn.filereadable(path) == 1
end

function M.dependencies()
  if vim.g.config_plugin_install or M.available() then
    return { "nvim-tree/nvim-web-devicons" }
  end
  return {}
end

function M.check()
  local features = require("config.plugins").status().features
  if not (features.statusline.available or features.buffers.available) then
    return
  end
  vim.health.start("File icons")
  if M.available() then
    vim.health.ok("nvim-web-devicons is available")
  else
    vim.health.warn("File icons are unavailable; statusline and buffer navigation remain usable", {
      "Run :ConfigPluginsInstall and restart Neovim",
    })
  end
end

return M
