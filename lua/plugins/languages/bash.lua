-- make zsh files recognized as sh for bash-ls & treesitter
vim.filetype.add({
  extension = {
    zsh = "sh",
    sh = "sh", -- force sh-files with zsh-shebang to still get sh as filetype
  },
  filename = {
    [".zshrc"] = "sh",
    [".zshenv"] = "sh",
  },
})

vim.lsp.config("bashls", {
  filetypes = { "sh", "zsh", "bash" },
})
vim.lsp.enable("bashls")

local M = {
  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "shfmt" } },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        fish = { "fish_indent" }, -- Installed with fish
      },
    },
    optional = true,
  },

  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        fish = { "fish" },
        bash = { "bash" },
      },
    },
  },
}

return M
