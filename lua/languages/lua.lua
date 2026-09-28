return {
  servers = { "lua_ls" },
  tools = {
    { mason = "lua-language-server", executable = "lua-language-server" },
    { mason = "stylua", executable = "stylua" },
  },
  parsers = { "lua" },
  formatters = {
    lua = { "stylua" },
  },
  plugins = {
    {
      "saghen/blink.cmp",
      optional = true,
      opts = function(_, opts)
        table.insert(opts.sources.default, 1, "lazydev")
        opts.sources.providers.lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 90,
        }
      end,
    },
    {
      "folke/lazydev.nvim",
      ft = "lua", -- only load on lua files
      opts = {
        library = {
          -- See the configuration section for more details
          -- Load luvit types when the `vim.uv` word is found
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          { path = "snacks.nvim", words = { "Snacks" } },
        },
      },
    },
  },
}
