-- Audit current declarations and runtime ownership; no copied key inventory.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
dofile(root .. "/tests/setup.lua")
vim.o.loadplugins = true
dofile(root .. "/init.lua")
dofile(root .. "/tests/native_plugins.lua")
assert(
  vim.wait(3000, function()
    return vim.g.config_ready == true
  end),
  "ConfigReady was not reached"
)
local actions = dofile(root .. "/tests/actions.lua")
local count = 0
for _, ft in ipairs({ "lua", "python", "tex", "markdown", "typst", "" }) do
  vim.cmd("enew!")
  vim.bo.filetype = ft
  count = count + actions.audit()
end
-- Every selected grouped action must agree with the central layout; aliases may
-- not survive under another owner. Text edits and local UI keys are independent.
local expected = {}
for id, entry in pairs(require("config.toggle_keys").list()) do
  expected[id:find("%.") and id or "toggle." .. id] = entry.lhs
end
for _, entries in pairs(require("config.bindings").entries) do
  for _, entry in ipairs(entries) do
    if expected[entry.id] then
      assert(entry[1] == expected[entry.id], "Layout mismatch: " .. entry.id)
    end
  end
end
for _, key in ipairs({
  "<leader>to",
  "<leader>ggP",
  "<leader>Dt",
  "<leader>ui",
  "<leader>z",
  "<leader>Z",
  "<leader>e",
  "<leader>ot",
  "<leader>go",
  "<leader>gl",
  "<leader>gL",
  "<leader>gq",
  "<leader>gd",
  "<A-z>",
  "<A-i>",
}) do
  assert(vim.fn.maparg(key, "n") == "", "Old toggle alias remains: " .. key)
end
require("features.lsp.keymaps").attach(vim.api.nvim_get_current_buf())
assert(vim.fn.maparg("<leader>d", "n") ~= "", "Single-action diagnostics changed")
assert(vim.fn.maparg("<leader>tws", "t") == "", "Terminal input acquired a Space prefix")
assert(count > 0, "No configured mappings were checked")
assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
io.stdout:write("Current mapping declarations: " .. count .. " effective mode/filetype bindings checked\n")
