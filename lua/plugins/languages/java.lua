return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = { ensure_installed = { "java" } },
    opts_extend = { "ensure_installed" },
  },
  {
    "mason-org/mason.nvim",
    optional = true,
    opts = { ensure_installed = { "jdtls" } },
    opts_extend = { "ensure_installed" },
  },
}
