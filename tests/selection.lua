local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
local before = #vim.api.nvim_get_autocmds({})
local schema = require("config.selection_schema")
local source = { profiles = { "data" }, features = { debugging = true } }
local normalized = schema.normalize(source)
source.profiles[1] = "writing"
source.features.debugging = false
assert(vim.deep_equal(normalized.profiles, { "data" }))
assert(normalized.features.debugging and not normalized.features.tasks)
assert(not package.loaded["config.context"] and not package.loaded.languages)

for _, bad in ipairs({
  { selection = { profiles = { "typo" }, features = {} }, message = "Unknown language profile: typo" },
  { selection = { profiles = { false }, features = {} }, message = "Profile names must be non-empty strings" },
  { selection = { profiles = { data = true }, features = {} }, message = "Selection.profiles must be a list" },
  { selection = { profiles = {}, features = { ai = "yes" } }, message = "Feature must be boolean: ai" },
  { selection = { profiles = {}, features = {}, typo = true }, message = "Unknown selection field: typo" },
}) do
  local ok, err = pcall(schema.normalize, bad.selection)
  assert(not ok and tostring(err):find(bad.message, 1, true), tostring(err))
end

local languages = require("languages")
local resolved = languages.resolve(normalized, {
  executable = function()
    return nil
  end,
})
assert(vim.deep_equal(resolved.servers, { "basedpyright" }))
assert(not package.loaded["config.context"], "Independent language resolution must not load the active context")
assert(#vim.api.nvim_get_autocmds({}) == before and not package.loaded.lazy)

local context = require("config.context")
local active = context.initialize(normalized)
assert(languages.current() == active.languages)
assert(context.initialize(normalized) == active)
local ok, err = pcall(context.initialize, source)
assert(not ok and tostring(err):find("restart to change selection", 1, true))
print("Selection validation, independent resolution and one-time context checks passed")
