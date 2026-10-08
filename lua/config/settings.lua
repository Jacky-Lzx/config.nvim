local M = {}
local current

function M.resolve(overrides, profile)
  if overrides == nil then
    overrides = {}
  end
  assert(type(overrides) == "table", "Configuration overrides must be a table")
  for key in pairs(overrides) do
    assert(key == "features" or key == "languages", "Unknown configuration setting: " .. tostring(key))
  end
  assert(overrides.features == nil or type(overrides.features) == "table", "features must be a table")
  for key, value in pairs(overrides.features or {}) do
    assert(key == "input" or key == "lsp" or key == "picker", "Unknown feature: " .. tostring(key))
    assert(type(value) == "boolean", "Feature must be boolean: " .. key)
  end
  assert(overrides.languages == nil or type(overrides.languages) == "table", "languages must be a table")
  for key, value in pairs(overrides.languages or {}) do
    assert(key == "lua", "Unknown language: " .. tostring(key))
    assert(type(value) == "boolean", "Language must be boolean: " .. key)
  end
  assert(
    profile == nil or profile == "default" or profile == "core",
    "Unknown configuration profile: " .. tostring(profile)
  )

  local settings = vim.tbl_deep_extend(
    "force",
    { features = { input = true, lsp = true, picker = true }, languages = { lua = true } },
    overrides
  )
  if profile == "core" then
    settings.features.input = false
    settings.features.lsp = false
    settings.features.picker = false
  end
  return settings
end

function M.current()
  if not current then
    local path = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "config", "local.lua")
    local overrides = {}
    if vim.fn.filereadable(path) == 1 then
      overrides = dofile(path)
      assert(type(overrides) == "table", "config/local.lua must return a table")
    end
    current = M.resolve(overrides, vim.env.NVIM_CONFIG_PROFILE)
  end
  return current
end

return M
