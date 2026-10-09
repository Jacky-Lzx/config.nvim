local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
local temp = assert(vim.env.NVIM_TEST_TMP, "NVIM_TEST_TMP is required")
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")

local Plugin = require("lazy.core.plugin")
local Config = require("lazy.core.config")
Config.options = vim.deepcopy(Config.defaults)
local shared = require("languages.markdown.specs.obsidian")[1]
assert(shared.opts.workspaces == nil, "Shared configuration must not declare an Obsidian workspace")

-- With no vault spec, Obsidian is disabled without becoming an uninstall candidate.
local standalone = Plugin.Spec.new({ vim.deepcopy(shared) }, { pkg = false })
assert(standalone.plugins["obsidian.nvim"] == nil)
assert(standalone.ignore_installed["obsidian.nvim"])

local vault = vim.fs.joinpath(temp, "vault")
vim.fn.mkdir(vim.fs.joinpath(vault, "nested"), "p")
vault = assert(vim.uv.fs_realpath(vault))
local local_file = vim.fs.joinpath(vault, ".lazy.lua")
vim.fn.writefile({
  "return {",
  "  {",
  '    "obsidian-nvim/obsidian.nvim",',
  "    optional = true,",
  "    lazy = false,",
  "    opts = {",
  ('      workspaces = { { name = "Fixture", path = %q } },'):format(vault),
  '      daily_notes = { template = "daily-note.md" },',
  "    },",
  "  },",
  "}",
}, local_file)

-- Exercise Lazy's real ancestor discovery and spec merging. This test-owned file
-- bypasses the interactive trust prompt; normal startup retains vim.secure.read.
Config.options.local_spec = true
vim.cmd.cd(vim.fs.joinpath(vault, "nested"))
local reads = 0
local secure_read = vim.secure.read
vim.secure.read = function(path)
  assert(path == local_file)
  reads = reads + 1
  return table.concat(vim.fn.readfile(path), "\n")
end
local local_spec = assert(Plugin.find_local_spec(), "Lazy must find the vault's .lazy.lua from a subdirectory")
local resolved = Plugin.Spec.new({ vim.deepcopy(shared), local_spec }, { pkg = false })
vim.secure.read = secure_read
assert(reads == 1 and #resolved.notifs == 0, vim.inspect(resolved.notifs))
local plugin = assert(resolved.plugins["obsidian.nvim"], "Local workspace must enable Obsidian")
local opts = Plugin.values(plugin, "opts", false)
assert(vim.deep_equal(opts.workspaces, { { name = "Fixture", path = vault } }))
assert(plugin.lazy == false and not plugin.optional, "Local optional spec must extend the shared plugin")
assert(opts.daily_notes.template == "daily-note.md" and opts.daily_notes.folder == "dailies")
assert(opts.notes_subdir == "notes" and shared.opts.workspaces == nil)
vim.cmd.cd(root)
print("Obsidian vault-local workspace discovery and option merging checks passed")
