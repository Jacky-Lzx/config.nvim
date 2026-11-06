local root = assert(vim.env.NVIM_CONFIG_ROOT)
local temp = assert(vim.env.NVIM_TEST_TMP)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
require("config.context").initialize({ profiles = { "writing" }, features = {} })
local specs = require("config.specs")
local shared = assert(vim.iter(require("languages.markdown.plugins")):find(function(spec)
  return type(spec) == "table" and spec.id == "obsidian-tools.nvim"
end))
assert(shared.enabled == true and shared.optional == true and shared.opts.workspaces == nil)
assert(shared.dir:match("/obsidian%-tools.nvim$"), "New Obsidian package remains local until published")
local resolve = require("plugin_tools.graph").resolve
local options = { dev = { path = require("utils.platform").dev_plugin_root(), fallback = true } }
local plain = resolve(specs.build(), options)
assert(not plain.nodes["obsidian-tools.nvim"] and not plain.packages["obsidian-tools.nvim"])
assert(plain.nodes["image-tools.nvim"].opts.insert.directory == "Figures")
local vault = temp .. "/vault"
vim.fn.mkdir(vault .. "/nested", "p")
vault = assert(vim.uv.fs_realpath(vault))
local file = vault .. "/.nvim-plugins.lua"
vim.fn.writefile({
  'return {{id="obsidian-tools.nvim",opts={workspaces={{name="Fixture",path='
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
local graph = resolve(specs.build(), options)
vim.secure.read = read
assert(reads == 1)
local obsidian = assert(graph.nodes["obsidian-tools.nvim"])
assert(vim.deep_equal(obsidian.opts.workspaces, { { name = "Fixture", path = vault } }))
assert(obsidian.opts.daily_notes.folder == "dailies" and obsidian.opts.daily_notes.template == "daily-note.md")
assert(obsidian.declarations[#obsidian.declarations].origin == file)
assert(obsidian.option_history[#obsidian.option_history].origin == file)
assert(obsidian.dependencies["markdown-tools.nvim"] == false)
assert(graph.nodes["image-tools.nvim"].opts.insert.directory == "assets/imgs")
assert(graph.nodes["image-tools.nvim"].parents["obsidian-tools.nvim"])
assert(shared.opts.workspaces == nil)
vim.opt.rtp:append(obsidian.dir)
vim.opt.rtp:append(graph.nodes["markdown-tools.nvim"].dir)
vim.opt.rtp:append(graph.nodes["keymap-tools.nvim"].dir)
local normalized = require("obsidian_tools.config").normalize(obsidian.opts)
assert(normalized.workspaces[1].path == vault)
assert(normalized.daily_notes.template == "daily-note.md")
assert(not package.loaded["obsidian_tools.index"], "Configuration must not scan a vault")
local file = vault .. "/nested/note.md"
vim.fn.writefile({ "# Fixture" }, file)
vim.cmd.edit(file)
vim.bo.filetype = "markdown"
local integration = require("integrations.obsidian")
vim.g.mapleader = " "
integration.setup(obsidian.opts)
assert(vim.fn.exists(":ObsidianTools") == 2)
assert(vim.fn.maparg("<Space>OO", "n", false, true).buffer == 1)
assert(not package.loaded["obsidian_tools.index"], "Attaching must not scan a vault")
local tools = require("obsidian_tools")
local selected, action
local original_select, original_refresh = vim.ui.select, tools.refresh
vim.ui.select = function(items, opts, callback)
  assert(opts.prompt == "Obsidian Commands")
  assert(vim.tbl_contains(items, "refresh"))
  selected = callback
  return "menu"
end
tools.refresh = function()
  action = true
end
assert(tools.menu() == "menu")
selected(nil)
assert(not action)
tools.menu()
selected("refresh")
assert(vim.wait(1000, function()
  return action
end))
tools.refresh, vim.ui.select = original_refresh, original_select
local callback = vim.fn.maparg("<Space>OO", "n", false, true).rhs
integration.setup(obsidian.opts)
assert(vim.fn.maparg("<Space>OO", "n", false, true).rhs == callback)
vim.cmd("enew!")
vim.api.nvim_buf_set_name(0, temp .. "/outside.md")
vim.bo.filetype = "markdown"
assert(vim.fn.maparg("<Space>OO", "n") == "")
assert(vim.fn.exists(":ObsidianTools") == 0)
assert(not package.loaded.obsidian)
vim.cmd.cd(root)
print("Optional native Obsidian selection, cold setup, buffer isolation and menu dispatch passed")
