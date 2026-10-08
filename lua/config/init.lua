local M = {}

function M.setup()
  assert(vim.fn.has("nvim-0.12") == 1, "This configuration requires Neovim 0.12 or newer")

  vim.g.mapleader = " "
  vim.g.maplocalleader = " "
  vim.loader.enable()

  require("core.options").setup()
  require("core.keymaps").setup()
  require("core.autocmds").setup()
  require("core.commands").setup()
  require("config.plugins").setup()
  require("features.treesitter").setup()
  require("features.lsp").setup()
end

function M.info()
  local version = vim.version()
  return {
    version = ("%d.%d.%d"):format(version.major, version.minor, version.patch),
    features = vim.deepcopy(require("config.settings").current().features),
    languages = vim.deepcopy(require("config.settings").current().languages),
    lsp = require("features.lsp").status(),
    treesitter = require("features.treesitter").status(),
    plugins = require("config.plugins").status(),
    paths = {
      config = vim.fn.stdpath("config"),
      data = vim.fn.stdpath("data"),
      state = vim.fn.stdpath("state"),
      cache = vim.fn.stdpath("cache"),
    },
  }
end

return M
