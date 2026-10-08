local M = {}

function M.check()
  local status = require("features.treesitter").status()
  vim.health.start("Tree-sitter")
  if not status.enabled then
    vim.health.ok("Managed syntax features are disabled")
    return
  end
  vim.health.info("Parser and query directory: " .. status.install_dir)
  if #status.parsers == 0 then
    vim.health.info("No parsers selected")
    return
  end
  for _, parser in ipairs(status.parsers) do
    if parser.installed then
      vim.health.ok(parser.name .. ": " .. parser.path)
      vim.health.info("Parser revision: " .. parser.revision)
    else
      vim.health.warn(parser.name .. " managed parser is missing or outdated", {
        "Run :ConfigPluginsInstall, restart Neovim, then :TSInstallConfigured",
      })
    end
  end
  local tools = require("features.treesitter.tools").status()
  if tools.available then
    vim.health.ok("Parser installation tools are available (tree-sitter-cli " .. tools.version .. ")")
  else
    vim.health.info("Parser installation requires: " .. table.concat(tools.missing, ", "))
  end
end

return M
