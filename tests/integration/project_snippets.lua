local root, temp = assert(vim.env.NVIM_CONFIG_ROOT), assert(vim.env.NVIM_TEST_TMP)
vim.opt.rtp:prepend(root)
vim.o.loadplugins = true
dofile(root .. "/tests/support/setup.lua")
local project = temp .. "/project-snippets"
vim.fn.mkdir(project .. "/nested/snippets", "p")
vim.fn.mkdir(project .. "/snippets", "p")
vim.fn.mkdir(vim.fn.stdpath("state"), "p")
project = assert(vim.uv.fs_realpath(project))
local manifest = project .. "/.nvim-plugins.lua"
local collection = project .. "/snippets/lua.lua"
vim.fn.writefile({ 'return {{id="snippet-tools.nvim",opts={project={paths={"snippets"}}}}}' }, manifest)
vim.fn.writefile({ 'return {{trigger="projectfn",body="project(${1:value})$0"}}' }, collection)
assert(vim.secure.trust({ path = manifest, action = "allow" }))
assert(vim.secure.trust({ path = collection, action = "allow" }))
vim.cmd.cd(project .. "/nested")
dofile(root .. "/init.lua")
dofile(root .. "/tests/support/native_plugins.lua")
assert(require("config.specs").project_root() == project)
assert(not package.loaded.snippet_tools, "Project options initialized snippets during startup")
local configured = require("config.plugins").nodes()["snippet-tools.nvim"].opts
assert(configured.project.paths[1] == "snippets" and configured.project.root == nil)
vim.cmd.cd(root)
vim.api.nvim_buf_set_name(0, project .. "/new.lua")
vim.bo.filetype = "lua"
local engine = require("snippet_tools.bootstrap").ensure()
local function find()
  local global, selected = false, nil
  for _, entry in ipairs(engine.available()) do
    global = global or entry.root == nil
    if entry.trigger == "projectfn" then
      selected = entry
    end
  end
  return selected, global
end
local selected, global = find()
assert(selected and selected.root == project and selected.source == collection)
assert(global, "Project paths replaced the global collections")
assert(engine.inspect().sources and engine.inspect().definitions)
vim.fn.writefile({ 'return {{trigger="projectfn",body="updated(${1:value})$0"}}' }, collection)
local confirm, prompts = vim.fn.confirm, 0
vim.fn.confirm = function()
  prompts = prompts + 1
  return 1
end
assert(engine.reload() and not find() and prompts == 1)
assert(vim.secure.trust({ path = collection, action = "allow" }))
assert(engine.reload() and find())
vim.fn.confirm = confirm
vim.cmd("enew!")
vim.api.nvim_buf_set_name(0, temp .. "/outside.lua")
vim.bo.filetype = "lua"
assert(not find(), "Project definitions leaked into another directory")
assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
vim.cmd.cd(root)
io.stdout:write(
  "Configured project snippets: trusted root, lazy setup, global coexistence, isolation and trust reload passed\n"
)
