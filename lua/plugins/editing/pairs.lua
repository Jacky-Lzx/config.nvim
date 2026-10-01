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
    opts = { mappings = { cr = false } },
    config = function(_, opts)
      require("pairs").setup(opts)
    end,
  },
}
