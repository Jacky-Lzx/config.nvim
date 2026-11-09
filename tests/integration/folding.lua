-- Configuration owns fold options, physical keys and saved-session expressions.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
local native_k = vim.fn.maparg("K", "n", false, true)
dofile(root .. "/tests/support/setup.lua")
dofile(root .. "/init.lua")
dofile(root .. "/tests/support/native_plugins.lua")
local fold = require("ui_tools.fold")
local declared = require("config.plugins").options("ui-tools.nvim").fold
assert(fold.enabled and fold.options.suffix == declared.suffix)
assert(fold.options.suffix == "  󰁂 %d")
assert(require("features.folding") == fold)
for _, key in ipairs({ "zM", "zr", "za", "zo", "zc", "zE", "zx", "zX" }) do
  assert(vim.fn.maparg(key, "n") == "", "Native fold key overridden: " .. key)
end
assert(vim.deep_equal(vim.fn.maparg("K", "n", false, true), native_k))
vim.cmd.enew()
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "local function outer()",
  "  if true then",
  "    print(1)",
  "    print(2)",
  "  end",
  "end",
})
vim.bo.filetype = "lua"
assert(vim.wait(2000, function()
  return vim.wo.foldlevel == 99 and vim.fn.foldlevel(3) >= 2
end))
vim.cmd("normal! zM")
local text = vim.fn.foldtextresult(1)
assert(text == "local function outer()  󰁂 5")
local expression = vim.wo.foldtext
vim.wo.foldtext = "v:lua.require'features.folding'.text()"
assert(vim.fn.foldtextresult(1) == text, "Saved-session expression stopped working")
vim.wo.foldtext = expression
vim.api.nvim_feedkeys("1zS", "xt", false)
assert(vim.wo.foldlevel == 1)
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.api.nvim_feedkeys("zK", "xt", false)
assert(vim.b.lsp_floating_preview and vim.api.nvim_win_is_valid(vim.b.lsp_floating_preview))
print("Configured folding: declared options, native keys, custom actions and saved-session expressions passed")
