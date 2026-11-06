local root = assert(vim.env.NVIM_CONFIG_ROOT)
local temp = assert(vim.env.NVIM_TEST_TMP)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(assert(vim.env.NVIM_PLUGIN_TOOLS_PATH))
require("config.context").initialize({ profiles = { "writing" }, features = {} })
local specs = require("config.specs")
local shared = assert(vim.iter(require("languages.markdown.plugins")):find(function(spec)
  return type(spec) == "table" and spec.id == "obsidian.nvim"
end))
assert(shared.enabled == true and shared.optional == true and shared.opts.workspaces == nil)
assert(shared.version == nil, "Use the lock and upstream HEAD; the native manager has no wildcard version solver")
local resolve = require("plugin_tools.graph").resolve
local options = { dev = { path = require("utils.platform").dev_plugin_root(), fallback = true } }
local plain = resolve(specs.build(), options)
assert(not plain.nodes["obsidian.nvim"] and not plain.packages["obsidian.nvim"])
assert(plain.nodes["image-tools.nvim"].opts.insert.directory == "Figures")
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
local graph = resolve(specs.build(), options)
vim.secure.read = read
assert(reads == 1)
local obsidian = assert(graph.nodes["obsidian.nvim"])
assert(vim.deep_equal(obsidian.opts.workspaces, { { name = "Fixture", path = vault } }))
assert(obsidian.opts.daily_notes.folder == "dailies" and obsidian.opts.daily_notes.template == "daily-note.md")
assert(obsidian.declarations[#obsidian.declarations].origin == file)
assert(obsidian.option_history[#obsidian.option_history].origin == file)
assert(next(obsidian.dependencies) == nil)
assert(graph.nodes["image-tools.nvim"].opts.insert.directory == "assets/imgs")
assert(graph.nodes["image-tools.nvim"].parents["obsidian.nvim"])
assert(obsidian.opts.picker.name == nil and shared.opts.workspaces == nil)
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/plugin-tools/obsidian.nvim")
local normalized = require("obsidian.config").normalize(obsidian.opts)
assert(normalized.picker.name == nil)
local default_picker = require("obsidian.picker.default")
local native_calls, select_calls, choices = 0, 0
default_picker.select = function(_, opts)
  native_calls = native_calls + 1
  assert(opts.preview_item or opts.allow_multiple or opts.query or opts.selection_mappings)
  return "native"
end
local integration = require("integrations.obsidian")
integration.setup()
local adapter = default_picker.select
integration.setup()
assert(default_picker.select == adapter, "Repeated setup must not wrap the adapter again")
local picker = require("obsidian.picker").get(normalized.picker.name)
assert(type(picker.select) == "function")
local original_select = vim.ui.select
local items = { "today", "search", false }
local selected = items[2]
vim.ui.select = function(actual, opts, callback)
  select_calls = select_calls + 1
  assert(actual == items and opts.prompt == "Obsidian Commands")
  callback(selected)
  return "select"
end
local function choose(value)
  choices = value
end
assert(picker.select(items, { prompt = "Obsidian Commands" }, choose) == "select")
assert(vim.deep_equal(choices, { "search" }))
selected = nil
picker.select(items, { prompt = "Obsidian Commands" }, choose)
assert(vim.deep_equal(choices, {}), "Cancellation must return an empty list to Obsidian")
selected = false
picker.select(items, { prompt = "Obsidian Commands" }, choose)
assert(vim.deep_equal(choices, { false }), "A false item is still a selection")
for _, opts in ipairs({
  { preview_item = function() end },
  { allow_multiple = true },
  { query = "note" },
  { selection_mappings = {} },
}) do
  assert(picker.select(items, opts, choose) == "native")
end
assert(select_calls == 3 and native_calls == 4)
vim.ui.select = original_select
assert(not package.loaded["snacks.picker"] and not package.loaded.lazy)
vim.cmd.cd(root)
print("Optional Obsidian project selection, workspace merging and selected-only image options passed")
