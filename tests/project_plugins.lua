local root, temp = assert(vim.env.NVIM_CONFIG_ROOT), assert(vim.env.NVIM_TEST_TMP)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
require("config.context").initialize({ profiles = { "writing" }, features = {} })
local configure = function()
  error("Manifest resolution must not configure plugins")
end
local declarations = require("languages.markdown.plugins")
declarations[#declarations + 1] = {
  id = "project-fixture",
  dir = temp .. "/uninstalled-project-plugin",
  optional = true,
  config = configure,
  opts = { ui = { border = "rounded", width = 30 }, list = { 1, 2 } },
}
local build, resolve = require("config.specs").build, require("plugin_tools.graph").resolve
local options = { dev = { path = require("utils.platform").dev_plugin_root(), fallback = true } }
assert(not resolve(build(), options).nodes["project-fixture"])
local project = temp .. "/project-selection"
vim.fn.mkdir(project .. "/nested", "p")
project = assert(vim.uv.fs_realpath(project))
local file = project .. "/.nvim-plugins.lua"
vim.fn.writefile({ "return {}" }, file)
vim.cmd.cd(project .. "/nested")
local secure_read, reads = vim.secure.read, 0
local contents
vim.secure.read = function(path)
  assert(path == file)
  reads = reads + 1
  return contents
end
local function graph(text)
  contents = text
  return resolve(build(), options)
end
assert(not graph(nil).nodes["project-fixture"], "An untrusted project file selected a plugin")
assert(not graph("return {}").nodes["project-fixture"])
assert(not graph('return {{id="project-fixture",enabled=false}}').nodes["project-fixture"])
assert(not graph('return {{id="project-fixture",optional=true}}').nodes["project-fixture"])
local selected = graph('return {{id="project-fixture",opts={ui={width=50},list={3}}}}')
local node = assert(selected.nodes["project-fixture"])
assert(node.dir == vim.fs.normalize(temp .. "/uninstalled-project-plugin") and node.config == configure)
assert(vim.deep_equal(node.opts, { ui = { border = "rounded", width = 50 }, list = { 3 } }))
assert(node.declarations[1].origin == "languages.markdown.plugins" and node.declarations[1].optional)
assert(node.declarations[2].origin == file)
assert(selected.packages["project-fixture"])
assert(not vim.list_contains(vim.api.nvim_list_runtime_paths(), node.dir))
assert(reads == 5, "Read the nearest trusted project file only once per manifest build")
vim.secure.read = secure_read
vim.cmd.cd(root)
print("Generic optional project plugins: absent, untrusted, disabled, optional-only and selected declarations passed")
