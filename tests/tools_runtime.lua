local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.o.loadplugins = true
dofile(root .. "/tests/setup.lua")
dofile(root .. "/init.lua")
vim.wait(100, function()
  return false
end, 10)
local plugins = require("lazy.core.config").plugins
assert(not plugins["mason.nvim"] and not package.loaded.mason and not package.loaded["mason-registry"])
for _, path in ipairs(vim.opt.rtp:get()) do
  assert(not path:match("/mason%.nvim"), path)
end
local commands = vim.api.nvim_get_commands({})
assert(commands.Mason == nil and commands.MasonToolsInstall ~= nil)
local java_home = require("utils.platform").jdtls_java_home()
if java_home and plugins["nvim-lspconfig"] then
  require("lazy").load({ plugins = { "nvim-lspconfig" } })
  assert(vim.lsp.config.jdtls.cmd_env.JAVA_HOME == java_home)
end
local tools = require("toolchain.tools")
local count = 0
for _, requirement in ipairs(require("integrations.toolchain").requirements("tool")) do
  local path = requirement.resolve and requirement.resolve()
    or requirement.executable and vim.fn.exepath(requirement.executable)
  assert(path and path ~= "" and vim.fn.executable(path) == 1, requirement.name)
  local real = vim.uv.fs_realpath(path) or path
  assert(not real:find("/mason/", 1, true), "Legacy dependency: " .. real)
  count = count + 1
end
local python = assert(require("utils.platform").debugpy_python())
assert(python == tools.path("debugpy", "python"))
assert(not python:find("/mason/", 1, true))
local server = assert(require("languages.vue.compatibility").server_path())
assert(not server:find("/mason/", 1, true))
local package_json = assert(io.open(server .. "/package.json"))
package_json:close()
assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
io.stdout:write(
  "Independent tools runtime: " .. count .. " configured requirements, debugpy and Vue resources passed\n"
)
