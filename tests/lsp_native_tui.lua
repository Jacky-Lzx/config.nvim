local root = assert(vim.env.NVIM_CONFIG_ROOT)
local plugin = assert(vim.env.LSP_TOOLS_ROOT)
vim.opt.rtp:prepend(root)
dofile(root .. "/tests/toolchain_sessions.lua")
require("config.context").initialize({ profiles = {}, features = {} })
vim.g.loaded_wakatime = true
vim.o.loadplugins = true
dofile(root .. "/init.lua")
require("lazy").load({ plugins = { "lsp-tools.nvim" } })
local spec = require("lazy.core.config").plugins["lsp-tools.nvim"]
local opts = require("lazy.core.plugin").values(spec, "opts", false)
assert(opts.rename.backend == "native" and opts.code_actions.backend == "native")
assert(opts.rename.native.file_header == false and opts.code_actions.native.file_header == false)
vim.env.LSP_TOOLS_BACKEND = "native"
if vim.env.LSP_NATIVE_CASE == "rename" then
  vim.env.LSP_TOOLS_CONFIG, vim.env.LSP_TOOLS_REAL_LSP = "1", "1"
  dofile(plugin .. "/tests/rename_integration.lua")
else
  dofile(plugin .. "/tests/integration.lua")
end
