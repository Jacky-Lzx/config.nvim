-- Explicit installer: nvim --headless -u NONE -i NONE -l scripts/install-plugins.lua
local root = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
vim.opt.runtimepath:prepend(root)
local settings = require("config.plugins").settings()
require("config.plugin_bootstrap").ensure(settings.url_format)
local manager = require("plugin_tools").new(settings)
local task = manager:install()
local result, err = task:wait(300000)
assert(result, tostring(err))
for _, id in ipairs(manager.graph.package_order) do
  local package = manager.graph.packages[id]
  if package.managed then
    local entry = assert(require("plugin_tools.util").read_json(manager.lockfile).plugins[id])
    assert(vim.uv.fs_stat(package.dir .. "/.git/plugin-tools-owner.json"))
    print(id .. " " .. entry.commit)
  end
end
print("Plugin installation complete; restart Neovim to activate the installed versions")
