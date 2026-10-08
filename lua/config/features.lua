local M = { names = { "ai", "debugging", "tasks", "sessions" } }

function M.normalize(features)
  assert(type(features) == "table", "Selection.features must be a table")
  for name, enabled in pairs(features) do
    assert(vim.list_contains(M.names, name), "Unknown feature: " .. tostring(name))
    assert(type(enabled) == "boolean", "Feature must be boolean: " .. name)
  end
  local result = {}
  for _, name in ipairs(M.names) do
    result[name] = features[name] == true
  end
  return result
end

return M
