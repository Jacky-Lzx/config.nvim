local M = {}
local source

function M.source()
  if not source then
    local dir = vim.fs.joinpath(require("config.platform").dev_plugin_root(), "pairs.nvim")
    source = {
      dir = dir,
      available = vim.fn.filereadable(vim.fs.joinpath(dir, "lua", "pairs", "init.lua")) == 1,
    }
  end
  return source
end

return M
