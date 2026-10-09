local M = {}

function M.setup()
  assert(vim.fn.has("nvim-0.12") == 1, "This configuration requires Neovim 0.12 or newer")

  -- required by nvim-tree
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

  vim.loader.enable()

  -- Keep startup order explicit; plugin-dependent work lives in plugin specs.
  require("core.options").setup()
  require("core.keymaps").setup()
  require("core.commands").setup()
  require("core.autocmds").setup()

  require("extra.profiling").setup()

  require("features.lsp.init").setup()

  -- require("config.keymaps")
  -- require("config.commands")
  -- require("config.autocmds")
  -- require("config.lsp")
  -- require("config.diagnostics")

  if vim.g.neovide then
    require("integrations.neovide")
  end

  require("config.lazy")
end

function M.info()
  local version = vim.version()
  return {
    version = ("%d.%d.%d"):format(version.major, version.minor, version.patch),
    paths = {
      config = vim.fn.stdpath("config"),
      data = vim.fn.stdpath("data"),
      state = vim.fn.stdpath("state"),
      cache = vim.fn.stdpath("cache"),
    },
  }
end

return M
