local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
local lockfile = require("config.lockfile")
local source = root .. "/lazy-lock.json"
local original = vim.fn.readfile(source, "b")

vim.env.NVIM_LAZY_LOCKFILE = nil
local paths = require("utils.paths")
local config_path = paths.config
local fixture = assert(vim.env.NVIM_TEST_TMP) .. "/source-lock.json"
vim.fn.writefile(original, fixture, "b")
paths.config = function(name)
  assert(name == "lazy-lock.json")
  return fixture
end
assert(lockfile.resolve() == fixture, "Editable checkouts must update their own lock")
assert(vim.uv.fs_chmod(fixture, 292)) -- 0444: simulate a read-only deployment.
assert(vim.fn.filewritable(fixture) == 0)
local target = lockfile.resolve()
assert(vim.startswith(target, vim.fs.normalize(vim.fn.stdpath("state")) .. "/"))
assert(target ~= fixture and vim.deep_equal(vim.fn.readfile(target, "b"), original))

-- Runtime plugin operations may write here without changing store-backed config.
vim.fn.writefile({ '{"runtime-update":true}' }, target)
assert(vim.deep_equal(vim.fn.readfile(source, "b"), original))
assert(lockfile.resolve() == target)
assert(vim.deep_equal(vim.fn.readfile(target, "b"), original), "A new startup must restore the deployed lock")
assert(vim.uv.fs_chmod(fixture, 420)) -- 0644: deploy a different reviewed lock.
vim.fn.writefile({ '{"new-deployment":true}' }, fixture)
assert(vim.uv.fs_chmod(fixture, 292))
assert(lockfile.resolve() == target)
assert(vim.fn.readfile(target)[1] == '{"new-deployment":true}', "Deployments must replace stale runtime locks")
vim.fn.delete(target)
assert(lockfile.resolve() == target and vim.fn.filereadable(target) == 1)

local development = assert(vim.env.NVIM_TEST_TMP) .. "/development-lock.json"
vim.fn.writefile({ '{"development":true}' }, development)
vim.env.NVIM_LAZY_LOCKFILE = development
assert(lockfile.resolve() == development)
assert(vim.fn.readfile(development)[1] == '{"development":true}', "Do not overwrite the development lock")
assert(vim.deep_equal(vim.fn.readfile(source, "b"), original))
vim.env.NVIM_LAZY_LOCKFILE = nil
paths.config = config_path
assert(vim.uv.fs_chmod(fixture, 420))
print("Editable checkout, read-only deployment, lock restoration and explicit override checks passed")
