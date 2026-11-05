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
      id = "lsp-tools.nvim",
      opts = {
        lua = {
          -- Preserve the previous behavior in projects with their own .luarc.
          enabled = true,
          plugin_roots = {
            require("utils.platform").dev_plugin_root(),
            vim.fn.stdpath("data") .. "/plugin-tools",
          },
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            { path = "debug-tools.nvim", words = { "debug_tools" } },
          },
        },
      },
    },
  },
}
