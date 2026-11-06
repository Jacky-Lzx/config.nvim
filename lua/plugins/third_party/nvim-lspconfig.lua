return {
  {
    -- Config provider only; lsp-tools applies overrides and enables servers.
    id = "nvim-lspconfig",
    origin = "plugins.third_party.nvim-lspconfig",
    enabled = true,
    source = "neovim/nvim-lspconfig",
    mount = "on-demand",
  },
}
