local M = {}
local pending

function M.run()
  local feature = require("features.treesitter")
  local status = feature.status()
  if not status.enabled or not status.active then
    vim.notify("Enable Tree-sitter and run :ConfigPluginsInstall before installing parsers", vim.log.levels.WARN)
    return
  end
  if pending then
    vim.notify("Parser installation is already running", vim.log.levels.INFO)
    return pending
  end
  local missing = {}
  for _, parser in ipairs(status.parsers) do
    if not parser.installed then
      missing[#missing + 1] = parser.name
    end
  end
  if #status.parsers == 0 then
    vim.notify("No parsers selected", vim.log.levels.INFO)
    return
  elseif #missing == 0 then
    vim.notify("Selected parsers are already installed", vim.log.levels.INFO)
    return
  end
  local tools = require("features.treesitter.tools").status()
  if not tools.available then
    vim.notify("Parser installation requires: " .. table.concat(tools.missing, ", "), vim.log.levels.WARN)
    return
  end
  pending = require("nvim-treesitter").install(missing, { force = true })
  pending:await(vim.schedule_wrap(function(err, success)
    pending = nil
    if err or not success then
      vim.notify("Parser installation failed; inspect :TSLog", vim.log.levels.ERROR)
      return
    end
    vim.notify("Selected parsers installed. Restart Neovim to activate their versions.", vim.log.levels.INFO)
  end))
  return pending
end

return M
