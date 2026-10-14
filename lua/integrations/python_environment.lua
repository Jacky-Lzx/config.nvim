local M = {}

function M.setup(selector)
  require("languages.python.interpreter").set_provider(function()
    return selector.python()
  end)
end

return M
