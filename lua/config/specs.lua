local M = {}

function M.build(selection)
  selection = selection or require("config.selection")
  local optional = { "ai", "debugging", "tasks", "sessions" }
  for name, enabled in pairs(selection.features) do
    assert(vim.list_contains(optional, name), "Unknown feature: " .. name)
    assert(type(enabled) == "boolean", "Feature must be boolean: " .. name)
  end

  local specs = {}
  for _, group in ipairs({ "ui", "editing", "navigation", "coding", "git", "integrations" }) do
    specs[#specs + 1] = { import = "plugins." .. group }
  end
  for _, group in ipairs(optional) do
    if selection.features[group] then
      specs[#specs + 1] = { import = "plugins." .. group }
    end
  end
  vim.list_extend(specs, require("languages").resolve(selection).plugins)
  return specs
end

return M
