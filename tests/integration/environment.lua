-- Resolve paths without initializing features or installing dependencies.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
local scenarios = dofile(root .. "/tests/support/scenarios.lua")
require("config.context").initialize(scenarios[vim.env.NVIM_TEST_SCENARIO])
require("config.plugin_bootstrap").mount()
local settings = require("config.plugins").settings()
local graph = require("plugin_tools.graph").resolve(settings.specs, settings)
local entries = { { id = "plugin-tools.nvim", directory = vim.env.NVIM_PLUGIN_TOOLS_PATH } }
for id, package in pairs(graph.packages) do
  assert(vim.fn.isdirectory(package.dir) == 1, "Missing configured plugin: " .. id .. " at " .. package.dir)
  entries[#entries + 1] = { id = id, directory = package.dir, source = package.source, managed = package.managed }
end
table.sort(entries, function(a, b)
  return a.id < b.id
end)
vim.fn.writefile({ vim.json.encode(entries) }, vim.env.NVIM_TEST_TMP .. "/environment.json")
io.stdout:write("Resolved configured plugin directories; revisions and dirty state recorded in summary.json\n")
