local root = assert(vim.env.NVIM_CONFIG_ROOT)
local plugin = assert(vim.env.LSP_TOOLS_ROOT)
vim.opt.rtp:prepend(root)
dofile(root .. "/tests/support/toolchain_sessions.lua")
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
dofile(root .. "/tests/support/native_plugins.lua")
for _, id in ipairs({ "lsp-tools.nvim" }) do
  require("plugin_tools").activate(id)
end
local spec = require("config.plugins").nodes()["lsp-tools.nvim"]
local opts = vim.deepcopy((spec).opts)
assert(opts.rename.backend == "native" and opts.code_actions.backend == "native")
assert(opts.rename.native.file_header == false and opts.code_actions.native.file_header == false)
vim.env.LSP_TOOLS_BACKEND = "native"
if vim.env.LSP_NATIVE_CASE == "rename" then
  vim.env.LSP_TOOLS_CONFIG, vim.env.LSP_TOOLS_REAL_LSP = "1", "1"
  dofile(plugin .. "/tests/rename_integration.lua")
else
  dofile(plugin .. "/tests/integration.lua")
end
