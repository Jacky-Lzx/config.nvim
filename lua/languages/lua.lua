return {
  servers = { "lua_ls" },
  tools = {
    { package = "lua-language-server", executable = "lua-language-server" },
    { package = "stylua", executable = "stylua" },
  },
  parsers = { "lua" },
  formatters = {
    lua = { "stylua" },
  },
  plugins = {
    {
      "folke/lazydev.nvim",
      ft = "lua", -- only load on lua files
      opts = {
        library = {
          -- See the configuration section for more details
          -- Load luvit types when the `vim.uv` word is found
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          { path = "debug-tools.nvim", words = { "debug_tools" } },
        },
      },
    },
  },
}
