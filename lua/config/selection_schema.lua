local M = {}

function M.normalize(selection)
  assert(type(selection) == "table", "Selection must be a table")
  for key in pairs(selection) do
    assert(key == "profiles" or key == "features", "Unknown selection field: " .. tostring(key))
  end
  assert(type(selection.profiles) == "table" and vim.islist(selection.profiles), "Selection.profiles must be a list")
  local profiles = require("config.profiles")
  for _, profile in ipairs(selection.profiles) do
    assert(type(profile) == "string" and profile ~= "", "Profile names must be non-empty strings")
    assert(profiles[profile], "Unknown language profile: " .. profile)
  end
  return {
    profiles = vim.deepcopy(selection.profiles),
    features = require("config.features").normalize(selection.features),
  }
end

return M
