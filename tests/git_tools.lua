local root = vim.env.NVIM_CONFIG_ROOT or vim.fn.getcwd()
vim.opt.rtp:prepend(root)
local spec = dofile(root .. "/lua/plugins/git/git-tools.lua")[1]
local function plugin_dir(plugin)
  if plugin.dir then
    return plugin.dir
  end
  local name = plugin.id
  local dev_dir = require("utils.platform").dev_plugin_root() .. "/" .. name
  return vim.uv.fs_stat(dev_dir) and dev_dir or vim.fn.stdpath("data") .. "/plugin-tools/" .. name
end
vim.opt.rtp:prepend(plugin_dir(spec))
vim.opt.rtp:prepend(require("utils.platform").dev_plugin_root() .. "/keymap-tools.nvim")
local function toggle_state(key, buf)
  local rows, info = require("keymap_tools").list({ mode = "n", buf = buf })
  assert(#info.errors == 0, vim.inspect(info.errors))
  for _, row in ipairs(rows) do
    if row.keys == "<Space>" .. key then
      return row.toggle.state
    end
  end
  error("Missing toggle metadata: " .. key)
end
vim.o.swapfile = false
vim.g.mapleader = " "
spec.bootstrap({ opts = spec.opts, dir = spec.dir })
local fixture = assert(vim.env.NVIM_TEST_TMP) .. "/git-tools-config"
vim.fn.mkdir(fixture, "p")
local function git(...)
  local args = { "git", "-C", fixture, "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null" }
  vim.list_extend(args, { ... })
  local result = vim.system(args):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end
git("init", "-q")
git("config", "user.name", "Fixture")
git("config", "user.email", "fixture@example.invalid")
vim.fn.writefile({ "one", "two" }, fixture .. "/sample.txt")
git("add", ".")
git("commit", "-qm", "initial")
vim.cmd.edit(fixture .. "/sample.txt")
require("git_tools").setup(spec.opts)
local buf = vim.api.nvim_get_current_buf()
assert(vim.wait(5000, function()
  return vim.fn.maparg("ih", "o") ~= ""
end, 5))
assert(vim.fn.maparg("]h", "n") ~= "" and vim.fn.maparg("<leader>ggu", "n") ~= "")
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "changed" })
local overlay
for _, key in ipairs(require("config.bindings").entries[spec.id]) do
  if key[1] == "<leader>to" then
    overlay = key[2]
  end
end
overlay()
assert(vim.wait(5000, function()
  local s = require("git_tools.buffer").states[buf]
  return s.overlay and #s.hunks > 0
end, 5))
assert(toggle_state("to", buf) == true and toggle_state("ggP", buf) == true)
local hidden = vim.api.nvim_create_buf(false, true)
assert(toggle_state("to", hidden) == nil, "Overlay status must use the requested buffer")
require("git_tools").toggle_overlay(buf)
assert(vim.wait(5000, function()
  return toggle_state("to", buf) == false
end, 5))
assert(not package.loaded.gitsigns and not package.loaded["mini.diff"] and not package.loaded.diffview)
local ui_spec = dofile(root .. "/lua/plugins/ui/ui-tools.lua")[1]
assert(vim.deep_equal(ui_spec.opts.statuscolumn.git_patterns, { "GitTools" }))
vim.opt.rtp:prepend(plugin_dir(ui_spec))
ui_spec.config({ opts = ui_spec.opts, dir = ui_spec.dir })
local marks = require("ui_tools.scrollbar").providers.git_tools.callback({ buf = buf })
assert(#marks > 0 and marks[1].hl == "GitToolsChange", "Scrollbar adapter did not read real GitTools hunks")
local keys = {}
for _, key in ipairs(require("config.bindings").entries[spec.id]) do
  keys[key[1]] = true
end
for _, name in ipairs({ "<leader>ggc", "<leader>ggC", "<leader>ggv", "<leader>ggt", "<leader>ggo", "<leader>ggO" }) do
  assert(keys[name], name)
end
local lazygit_key
for _, key in ipairs(require("config.bindings").entries[spec.id]) do
  if key[1] == "<C-g>" then
    lazygit_key = key
  end
end
assert(lazygit_key and lazygit_key.desc == "[Git] Lazygit")
assert(type(require("git_tools").lazygit) == "function" and vim.fn.exists(":GitTools") == 2)

local staged
require("git_tools").stage_hunk({
  callback = function(err)
    assert(not err, err)
    staged = true
  end,
})
assert(vim.wait(5000, function()
  return staged
end, 5))
assert(git("show", ":sample.txt") == "changed\ntwo\n")
print("git_tools config: actual mappings, overlay and unsaved staging passed")
vim.cmd("qa!")
