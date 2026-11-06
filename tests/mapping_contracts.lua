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
assert(count > 0, "No configured mappings were checked")
assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
io.stdout:write("Current mapping declarations: " .. count .. " effective mode/filetype bindings checked\n")
