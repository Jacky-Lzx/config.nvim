vim.opt.rtp:prepend(assert(vim.env.NVIM_CONFIG_ROOT))
local bootstrap = require("config.plugin_bootstrap")
local temporary = assert(vim.env.NVIM_TEST_TMP) .. "/bootstrap"
local repository = temporary .. "/source/fixture"
vim.fn.mkdir(repository .. "/lua/plugin_tools", "p")
vim.fn.writefile({ "return {}" }, repository .. "/lua/plugin_tools/init.lua")
local function git(...)
  local args = { "git", "-C", repository }
  vim.list_extend(args, { ... })
  local result = vim.system(args, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout)
end
git("init", "--quiet")
git("add", "lua")
git(
  "-c",
  "commit.gpgsign=false",
  "-c",
  "user.name=Bootstrap Test",
  "-c",
  "user.email=bootstrap@example.invalid",
  "commit",
  "--quiet",
  "-m",
  "fixture"
)
bootstrap.source, bootstrap.commit = "fixture", git("rev-parse", "HEAD")
bootstrap.installed = function()
  return temporary .. "/installed/" .. bootstrap.commit
end
local old_dev, old_path = vim.env.NVIM_DEV_PLUGIN_ROOT, vim.env.NVIM_PLUGIN_TOOLS_PATH
vim.env.NVIM_DEV_PLUGIN_ROOT, vim.env.NVIM_PLUGIN_TOOLS_PATH = temporary .. "/dev", nil
assert(bootstrap.directory() == bootstrap.installed())
assert(not pcall(bootstrap.mount), "Startup must fail with an actionable message before installation")
assert(bootstrap.ensure(temporary .. "/source/%s") == bootstrap.installed())
local system = vim.system
vim.system = function()
  error("Startup must not invoke Git")
end
assert(bootstrap.mount() == bootstrap.installed())
assert(bootstrap.ensure(temporary .. "/source/%s") == bootstrap.installed())
vim.fn.mkdir(temporary .. "/dev/plugin-tools.nvim/lua/plugin_tools", "p")
vim.fn.writefile({ "return {}" }, temporary .. "/dev/plugin-tools.nvim/lua/plugin_tools/init.lua")
assert(bootstrap.directory() == temporary .. "/dev/plugin-tools.nvim")
vim.env.NVIM_PLUGIN_TOOLS_PATH = repository
assert(bootstrap.directory() == repository)
local old_root = vim.env.NVIM_PLUGIN_ROOT
vim.env.NVIM_PLUGIN_ROOT = temporary .. "/managed"
vim.fn.mkdir(temporary .. "/managed/library/lua/fixture", "p")
vim.fn.writefile({ "return { value = 'managed' }" }, temporary .. "/managed/library/lua/fixture/pure.lua")
local runtime = vim.o.runtimepath
assert(bootstrap.library("library", "fixture.pure").value == "managed")
vim.fn.delete(temporary .. "/managed/library", "rf")
assert(bootstrap.library("library", "fixture.pure").value == "managed", "Pure library must be cached")
assert(vim.o.runtimepath == runtime, "Pure library import mounted unrelated runtime scripts")
vim.env.NVIM_PLUGIN_ROOT = old_root
vim.system = system
vim.env.NVIM_DEV_PLUGIN_ROOT, vim.env.NVIM_PLUGIN_TOOLS_PATH = old_dev, old_path
print("Pinned manager bootstrap: explicit install, offline startup, development preference and override passed")
