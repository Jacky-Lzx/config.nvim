local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)

for name, kind in vim.fs.dir(root, { depth = math.huge }) do
  if kind == "file" and name:match("%.lua$") then
    assert(loadfile(root .. "/" .. name), name)
  end
end

local platform = require("config.platform")
assert(platform.os == "macos" or platform.os == "linux" or platform.os == "other")
assert(type(platform.open) == "function")

local languages = require("config.languages")
local enabled_profiles = languages.enabled_profiles
languages.enabled_profiles = { "base" }
assert(languages.is_enabled("lua"))
assert(languages.is_enabled("kdl"))
assert(not languages.is_enabled("java"))
assert(vim.list_contains(languages.enabled_lsp_servers(), "lua_ls"))
assert(not vim.list_contains(languages.enabled_lsp_servers(), "kdl"))
assert(not vim.list_contains(languages.enabled_lsp_servers(), "jdtls"))

languages.enabled_profiles = { "native" }
assert(languages.is_enabled("swift"))
assert(vim.list_contains(languages.enabled_lsp_servers(), "sourcekit"))

languages.enabled_profiles = { "base", "optional", "base" }
assert(languages.is_enabled("java"))
assert(vim.list_contains(languages.enabled_lsp_servers(), "jdtls"))
for _, values in ipairs({ languages.enabled_languages(), languages.enabled_lsp_servers() }) do
  local seen = {}
  for _, value in ipairs(values) do
    assert(not seen[value], "duplicate language/server: " .. value)
    seen[value] = true
  end
end
languages.enabled_profiles = {}
assert(#languages.enabled_languages() == 0)
assert(#languages.enabled_lsp_servers() == 0)
languages.enabled_profiles = enabled_profiles

dofile(root .. "/tests/lsp_config.lua")

vim.cmd("quitall!")
