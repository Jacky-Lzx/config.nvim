local M = {}

function M.check()
  vim.health.start("Neovim configuration")
  -- Validate startup declarations without probing tools or initializing plugins.
  local ok, err = pcall(function()
    local context = require("config.context")
    context.resolve(context.current().selection)
  end)
  if ok then
    vim.health.ok("Selected profiles and language declarations are valid.")
  else
    vim.health.error("Invalid configuration: " .. tostring(err), {
      "Correct the selected profiles, feature switches or language declarations",
    })
  end
  vim.health.info("Details: :ConfigInfo")
end

return M
