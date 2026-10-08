-- Run from the repo: nvim --headless -u NONE -i NONE --noplugin -l tests/mini_diff_lazy.lua
-- Also run with MINI_DIFF_TEST=direct to exercise setup + callback without yielding.
local root = vim.fn.getcwd()
local lazy_root = vim.fn.stdpath("data") .. "/lazy"
vim.opt.runtimepath:prepend(lazy_root .. "/lazy.nvim")
vim.opt.runtimepath:prepend(lazy_root .. "/mini.diff")
vim.o.swapfile = false
vim.g.mapleader = " "

local spec
for _, plugin in ipairs(dofile(root .. "/lua/plugins/git/mini-diff.lua")) do
  if plugin[1] == "echasnovski/mini.diff" then
    spec = plugin
  end
end
assert(spec and spec.event == nil, "Mini.diff must not load on VeryLazy (or any event)")
assert(#spec.keys == 1 and spec.keys[1][1] == "<leader>to")
assert(spec.keys[1].mode == "n" and spec.keys[1].desc == "[Mini.Diff] Toggle diff overlay")
for _, key in ipairs({ "apply", "reset", "textobject", "goto_first", "goto_prev", "goto_next", "goto_last" }) do
  assert(spec.opts.mappings[key] == "", "Keep gitsigns mappings: " .. key)
end

-- Use the existing tracked file and change only its in-memory buffer.
vim.cmd.edit(root .. "/init.lua")
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "-- mini.diff lazy-loading regression" })
assert(package.loaded["mini.diff"] == nil)

local loads = 0
local function setup()
  loads = loads + 1
  require("mini.diff").setup(spec.opts)
  assert(require("mini.diff").get_buf_data(buf) == nil, "Setup must not have auto-enabled yet")
end
local function press()
  vim.api.nvim_feedkeys(" to", "xt", false)
end

if vim.env.MINI_DIFF_TEST == "direct" then
  setup()
  spec.keys[1][2]()
  vim.keymap.set("n", spec.keys[1][1], spec.keys[1][2])
else
  -- Exercise the installed Lazy handler's mapping replacement and feedkeys replay.
  -- Substitute only plugin loading to avoid Lazy setup's filesystem/cache writes.
  local loader = require("lazy.core.loader")
  local original_load = loader.load
  loader.load = function(plugins, reason)
    assert(plugins["mini.diff"] and reason.keys == "<leader>to")
    setup()
  end
  local keys = require("lazy.core.handler.keys")
  local key = keys.parse(spec.keys[1])
  local handler = setmetatable({ active = { [key.id] = { ["mini.diff"] = "mini.diff" } } }, { __index = keys })
  handler:_add(key)
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
  assert(package.loaded["mini.diff"] == nil, "VeryLazy must not load Mini.diff")
  press()
  loader.load = original_load
end

local diff = require("mini.diff")
local data = diff.get_buf_data(buf)
assert(loads == 1 and data ~= nil, "First invocation must enable the buffer")
assert(data.overlay, "First invocation must turn overlay on")
assert(data.ref_text == nil, "Git reference must still be pending asynchronously")
local ns = vim.api.nvim_get_namespaces().MiniDiffOverlay
assert(
  vim.wait(5000, function()
    data = diff.get_buf_data(buf)
    vim.cmd.redraw()
    return data and data.ref_text ~= nil and #data.hunks > 0 and #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) > 0
  end, 10),
  "First overlay must render after Git reference arrives without another key"
)
assert(data.overlay)
assert(not data.ref_text:find("mini.diff lazy-loading regression", 1, true), "Reference must come from Git")
press()
assert(not diff.get_buf_data(buf).overlay, "Second invocation must turn overlay off")
assert(loads == 1, "Subsequent keys must not reload the plugin")
assert(
  vim.wait(1000, function()
    vim.cmd.redraw()
    return #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) == 0
  end, 10),
  "Second toggle must clear overlay decorations"
)
diff.disable(buf)
print("mini_diff_lazy: " .. (vim.env.MINI_DIFF_TEST or "Lazy key replay") .. " passed")
