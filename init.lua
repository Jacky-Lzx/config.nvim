-- Keep startup order explicit; plugin-dependent work lives in plugin specs.
require("config.options")
require("config.profiling")
require("config.keymaps")
require("config.commands")
require("config.autocmds")
require("config.lsp")
require("config.diagnostics")

if vim.g.neovide then
  require("integrations.neovide")
end

require("config.lazy")
