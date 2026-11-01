local root = vim.env.NVIM_CONFIG_ROOT or vim.fn.getcwd()
vim.opt.rtp:prepend(root)
local spec = dofile(root .. "/lua/plugins/git/git-tools.lua")[1]
vim.opt.rtp:prepend(spec.dir)
vim.o.swapfile = false
vim.g.mapleader = " "
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
for _, key in ipairs(spec.keys) do
  if key[1] == "<leader>to" then
    overlay = key[2]
  end
end
overlay()
assert(vim.wait(5000, function()
  local s = require("git_tools.buffer").states[buf]
  return s.overlay and #s.hunks > 0
end, 5))
assert(not package.loaded.gitsigns and not package.loaded["mini.diff"] and not package.loaded.diffview)
local snacks = dofile(root .. "/lua/plugins/navigation/snacks.lua")[1]
for _, key in ipairs(snacks.keys) do
  assert(not key[1]:match("^<leader>gg"), "Git keys must be owned by git-tools")
end
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
