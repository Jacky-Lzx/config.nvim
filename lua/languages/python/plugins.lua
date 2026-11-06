return {
  {
    id = "workspace-tools.nvim",
    source = "Jacky-Lzx/workspace-tools.nvim",
    version = "main",
    dev = true,
    mount = "on-demand",
    start = require("config.context").current().selection.features.sessions,
    children = {
      {
        id = "workspace-tools.python",
        ft = { "python" },
        opts = {
          python = {},
        },
        config = function(ctx)
          require("config.bindings").set(
            "workspace-tools.python",
            { { "<leader>cv", "<CMD>VenvSelect<CR>", desc = "Select VirtualEnv", ft = "python" } }
          )
          local opts = ctx.opts
          require("integrations.python_environment").setup(opts.python)
        end,
      },
    },
  },
  "languages.python.debug",
}
