return {
  {
    main = "crates",
    id = "crates.nvim",
    enabled = false,
    source = "Saecki/crates.nvim",
    opts = {
      completion = {
        crates = {
          enabled = true,
        },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
}
