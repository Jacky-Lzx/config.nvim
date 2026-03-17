vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      format = {
        -- This seems not working. The formatter is still enabled.
        enable = false,
      },
      -- Associated a schema url, relative , or absolute (to root of project, not to filesystem root) path to the a glob
      -- pattern relative to the detected project root.
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
      },
    },
  },
})

vim.lsp.enable("yamlls")

local M = {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = {
      ensure_installed = { "yaml" },
    },
    opts_extend = { "ensure_installed" },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        yaml = { "prettierd" },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "yaml-language-server" } },
  },
}

return M
