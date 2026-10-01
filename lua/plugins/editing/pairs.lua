return {
  { "windwp/nvim-autopairs", enabled = false },
  { "nvim-mini/mini.pairs", enabled = false },
  {
    dir = vim.fs.joinpath(require("config.platform").dev_plugin_root(), "pairs.nvim"),
    name = "pairs.nvim",
    event = "InsertEnter",
    cmd = { "PairsToggle", "PairsInspect" },
    keys = {
      {
        "<leader>tp",
        function()
          require("pairs").toggle()
        end,
        desc = "[Pairs] Toggle pairing",
      },
    },
    -- blink.cmp composes Enter after completion confirmation.
    opts = {
      treesitter = true,
      mappings = { cr = false },
      filetypes = {
        python = {
          multi_pairs = {
            [string.rep('"', 3)] = {},
            [string.rep("'", 3)] = {},
          },
        },
      },
    },
    config = function(_, opts)
      require("pairs").setup(opts)
    end,
  },
}
