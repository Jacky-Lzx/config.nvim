vim.opt.rtp:prepend(assert(vim.env.NVIM_CONFIG_ROOT))
local bindings, api = require("config.bindings"), vim.api
vim.g.mapleader = " "
local first, second = api.nvim_get_current_buf(), api.nvim_create_buf(true, false)
vim.bo[first].filetype, vim.bo[second].filetype = "lua", "python"
local calls = 0
local entries = {
  {
    "<leader>xy",
    function()
      calls = calls + 1
    end,
    mode = { "n", "x" },
  },
  { "<F24>", "<Nop>", ft = "lua" },
}
bindings.set("reload", entries)
bindings.set("reload", entries)
assert(#api.nvim_get_autocmds({ group = "ConfigBindings_reload", event = "FileType" }) == 1)
vim.fn.maparg("<leader>xy", "n", false, true).callback()
assert(calls == 1)
assert(vim.fn.maparg("<F24>", "n", false, true).buffer == 1)
api.nvim_set_current_buf(second)
assert(vim.fn.maparg("<F24>", "n") == "")
vim.bo[second].filetype = "lua"
assert(vim.fn.maparg("<F24>", "n", false, true).buffer == 1)
bindings.set("reload", {})
assert(vim.fn.maparg("<F24>", "n") == "" and vim.fn.maparg("<leader>xy", "x") == "")
api.nvim_set_current_buf(first)
assert(vim.fn.maparg("<F24>", "n") == "")
bindings.set("owner-a", { { "<F23>", "<Nop>" } })
bindings.set("owner-b", { { "<F23>", "<Nop>" } })
bindings.set("owner-a", {})
assert(vim.fn.maparg("<F23>", "n", false, true).lhs)
bindings.set("owner-b", {})
assert(vim.fn.maparg("<F23>", "n") == "")
bindings.set("manual", { { "<F22>", "<Nop>" } })
vim.keymap.set("n", "<F22>", "manual replacement")
bindings.set("manual", {})
assert(vim.fn.maparg("<F22>", "n") == "manual replacement")
bindings.set("leader", { { "<leader>xy", "<Nop>" } })
vim.g.mapleader = ","
bindings.set("leader", { { "<leader>xy", "<Nop>" } })
assert(vim.fn.maparg(" xy", "n") == "" and vim.fn.maparg(",xy", "n", false, true).lhs)
bindings.set("leader", {})
bindings.set("visual", { { "<F21>", "<Nop>", mode = "v" } })
bindings.set("visual", {})
assert(vim.fn.maparg("<F21>", "x") == "" and vim.fn.maparg("<F21>", "s") == "")
bindings.set("deleted", { { "<F20>", "<Nop>", buffer = second } })
api.nvim_buf_delete(second, { force = true })
bindings.set("deleted", {})
bindings.set("shadowed", { { "<F19>", "global" } })
vim.keymap.set("n", "<F19>", "buffer", { buffer = first })
bindings.set("shadowed", {})
assert(vim.fn.maparg("<F19>", "n") == "buffer", "Global cleanup must preserve buffer-local overrides")
for _, item in ipairs(api.nvim_get_keymap("n")) do
  assert(item.lhs ~= "<F19>", "Global mapping survived beneath a buffer-local override")
end
print(
  "Mapping reload: callbacks, filetypes, removed keys, ownership, manual overrides, modes and leader changes passed"
)
