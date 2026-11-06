return {
  {
    id = "workspace-tools.nvim",
    dir = require("utils.platform").dev_plugin_root() .. "/workspace-tools.nvim",
    start = require("config.context").current().selection.features.sessions,
    children = {
      {
        id = "workspace-tools.python",
        start = true,
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
          vim.api.nvim_create_user_command("VenvSelect", function(args)
            vim.api.nvim_cmd(
              { cmd = "WorkspacePython", args = args.args ~= "" and { args.args } or {}, bang = args.bang },
              {}
            )
          end, { nargs = "?", bang = true, complete = "file", desc = "Select project Python environment" })
        end,
      },
    },
  },
  "plugins.disabled.nvim-dap.python",
}
