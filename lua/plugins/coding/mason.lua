return {
  {
    "mason-org/mason.nvim",
    cmd = { "Mason" },
    -- nvim-lspconfig/nvim-lint and toolchain-tools load Mason before using tools.
    opts = {
      -- Keep Nix/system tools ahead of Mason's optional fallback executables.
      PATH = "append",
    },
  },
}
