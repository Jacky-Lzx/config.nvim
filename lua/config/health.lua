local M = {}

function M.check()
  local info = require("config").info()
  vim.health.start("Configuration")

  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim " .. info.version)
  else
    vim.health.error("Neovim 0.12 or newer is required")
  end

  local entry = vim.fs.joinpath(info.paths.config, "init.lua")
  if vim.fn.filereadable(entry) == 1 then
    vim.health.ok("Configuration entry: " .. entry)
  else
    vim.health.warn("No init.lua at the standard configuration path: " .. entry)
  end

  for _, name in ipairs({ "data", "state", "cache" }) do
    vim.health.info(name .. ": " .. info.paths[name])
  end
end

return M
