local M = {}
local provider, environment

-- The integration supplies live project selection; this module never loads a plugin.
function M.set_provider(resolve, resolve_environment)
  assert(resolve == nil or type(resolve) == "function", "Python interpreter provider must be a function or nil")
  assert(
    resolve_environment == nil or type(resolve_environment) == "function",
    "Python environment provider must be a function or nil"
  )
  provider, environment = resolve, resolve_environment
end

function M.current(opts)
  return require("utils.platform").python(provider and provider(opts) or nil)
end

function M.environment(opts)
  return environment and environment(opts) or {}
end

return M
