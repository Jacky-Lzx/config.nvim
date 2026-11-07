-- Test-only opt-in to exercise optional integrations without editing the user's
-- per-plugin enabled flags. Never loaded by production configuration.
if vim.env.NVIM_TEST_ENABLE_THIRD_PARTY ~= "1" or _G.full_plugins_fixture then
  return
end
_G.full_plugins_fixture = true
local root = assert(vim.env.NVIM_CONFIG_ROOT)
local modules = {
  ["languages.rust.crates"] = { "crates.nvim" },
}
for name, ids in pairs(modules) do
  local module_name, enabled_ids = name, ids
  package.preload[module_name] = function()
    local value = assert(loadfile(root .. "/lua/" .. module_name:gsub("%.", "/") .. ".lua"))()
    for _, spec in ipairs(value.plugins or value) do
      if vim.list_contains(enabled_ids, spec.id) then
        spec.enabled = true
      end
    end
    return value
  end
end
