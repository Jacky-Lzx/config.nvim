local M = {}
local provider

-- The integration supplies live project selection; this module never loads a plugin.
function M.set_provider(resolve)
  assert(resolve == nil or type(resolve) == "function", "Python interpreter provider must be a function or nil")
  provider = resolve
end

function M.current()
  return require("utils.platform").python(provider and provider() or nil)
end

return M
