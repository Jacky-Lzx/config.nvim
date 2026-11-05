local root = assert(vim.env.NVIM_CONFIG_ROOT)
local temp = assert(vim.env.NVIM_TEST_TMP)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
require("config.context").initialize({ profiles = { "writing" }, features = {} })
local specs = require("config.specs")
local shared = require("languages.markdown.specs.obsidian")[1]
assert(shared.opts.workspaces == nil)
local plain = specs.build()
for _, node in ipairs(plain) do
  assert(node.id ~= "obsidian.nvim")
end
local vault = temp .. "/vault"
vim.fn.mkdir(vault .. "/nested", "p")
vault = assert(vim.uv.fs_realpath(vault))
local file = vault .. "/.nvim-plugins.lua"
vim.fn.writefile({
  'return {{id="obsidian.nvim",opts={workspaces={{name="Fixture",path='
    .. string.format("%q", vault)
    .. '}},daily_notes={template="daily-note.md"}}}}',
}, file)
vim.cmd.cd(vault .. "/nested")
local read, reads = vim.secure.read, 0
vim.secure.read = function(path)
  assert(path == file)
  reads = reads + 1
  return table.concat(vim.fn.readfile(path), "\n")
end
local graph = require("plugin_tools.graph").resolve(
  specs.build(),
  { dev = { path = require("utils.platform").dev_plugin_root(), fallback = true } }
)
vim.secure.read = read
assert(reads == 1)
local obsidian = assert(graph.nodes["obsidian.nvim"])
assert(vim.deep_equal(obsidian.opts.workspaces, { { name = "Fixture", path = vault } }))
assert(obsidian.opts.daily_notes.folder == "dailies" and obsidian.opts.daily_notes.template == "daily-note.md")
assert(next(obsidian.dependencies) == nil)
assert(graph.nodes["image-tools.nvim"].opts.insert.directory == "assets/imgs")
assert(obsidian.opts.picker.name == false and shared.opts.workspaces == nil)
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/plugin-tools/obsidian.nvim")
local picker = require("obsidian.picker").get(false)
assert(picker.select == require("obsidian.picker.ui").select)
assert(not package.loaded["snacks.picker"] and not package.loaded.lazy)
vim.cmd.cd(root)
print("Secure project-native Obsidian workspace discovery, option merging and cold image configuration passed")
