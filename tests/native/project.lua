local root, temp = assert(vim.env.NVIM_CONFIG_ROOT), assert(vim.env.NVIM_TEST_TMP)
vim.opt.rtp:prepend(root)
local project = require("config.project")
local function fixture(name)
  local directory = temp .. "/" .. name
  vim.fn.mkdir(directory .. "/nested", "p")
  directory = assert(vim.uv.fs_realpath(directory))
  vim.fn.writefile({ "error('Discovery must never execute project code')" }, directory .. "/.nvim-plugins.lua")
  return directory
end
local first, second = fixture("first"), fixture("second")
local argv, cwd = vim.fn.argv, vim.uv.cwd()
vim.cmd.cd(first)
local arguments = {}
vim.fn.argv = function()
  return arguments
end
assert(project.startup_file() == first .. "/.nvim-plugins.lua")
arguments = { second .. "/nested/new.md" }
assert(project.startup_file() == second .. "/.nvim-plugins.lua", "File arguments must precede cwd")
arguments = { second }
assert(project.startup_file() == second .. "/.nvim-plugins.lua", "Directory arguments must work")
arguments = { "-", "https://example.test/file" }
assert(project.startup_file() == first .. "/.nvim-plugins.lua")
assert(project.find("https://example.test/file") == nil)
vim.fn.argv = argv
local notify, warnings = vim.notify, {}
vim.notify = function(message, level)
  assert(level == vim.log.levels.WARN)
  warnings[#warnings + 1] = message
end
project.setup(first .. "/.nvim-plugins.lua")
local function visit(path)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, path)
  vim.api.nvim_set_current_buf(buf)
end
visit(first .. "/nested/a.md")
visit(second .. "/nested/a.md")
visit(second .. "/nested/b.md")
assert(vim.wait(1000, function()
  return #warnings > 0
end))
assert(#warnings == 1 and warnings[1]:find("Restart Neovim", 1, true))
assert(project.info().file == first .. "/.nvim-plugins.lua", "Navigation must not replace the active selection")
vim.notify = notify
vim.api.nvim_del_augroup_by_name("ConfigProject")
vim.cmd.cd(cwd)
print("Project discovery: argv/cwd, new files, directories, URI/stdin and one-time cross-project warnings passed")
