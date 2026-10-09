local template_rules = {
  pairs = { ["`"] = { close = "`" } },
  multi_pairs = { ["${"] = {} },
}

return {
  { "windwp/nvim-autopairs", enabled = false },
  { "nvim-mini/mini.pairs", enabled = false },
  {
    "Jacky-Lzx/pairs.nvim",
    dev = true,
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
      tex_environments = { abstract = "text", theorem = "text", proof = "text" },
      mappings = { cr = false },
      filetypes = {
        markdown = { multi_pairs = { ["```"] = {}, ["~~~"] = {} } },
        tex = { multi_pairs = { ["$$"] = {}, ["\\("] = {}, ["\\["] = {} } },
        plaintex = { multi_pairs = { ["$$"] = {}, ["\\("] = {}, ["\\["] = {} } },
        javascript = vim.deepcopy(template_rules),
        javascriptreact = vim.deepcopy(template_rules),
        typescript = vim.deepcopy(template_rules),
        typescriptreact = vim.deepcopy(template_rules),
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
