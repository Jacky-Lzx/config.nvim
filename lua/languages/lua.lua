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
      id = "lua-tools.nvim",
      source = "Jacky-Lzx/lua-tools.nvim",
      version = "main",
      dev = true,
      main = "lua_tools",
      opts = {
        -- Explicitly retain library discovery in projects with their own .luarc.
        enabled = true,
        nvim = true,
        config_roots = { require("utils.paths").root },
        plugin_roots = {
          require("utils.platform").dev_plugin_root(),
          vim.env.NVIM_PLUGIN_ROOT or (vim.fn.stdpath("data") .. "/plugin-tools"),
        },
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          { path = "debug-tools.nvim", words = { "debug_tools" } },
        },
      },
    },
  },
}
