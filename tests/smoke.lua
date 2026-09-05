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
assert(languages.is_enabled("lua"))
assert(not languages.is_enabled("java"))
assert(vim.list_contains(languages.enabled_lsp_servers(), "lua_ls"))
assert(not vim.list_contains(languages.enabled_lsp_servers(), "jdtls"))

vim.cmd("quitall!")
