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
  {
    id = "nvim-dap",
    opts = {
      adapters = {
        python = function(cb, config)
          if config.request == "attach" then
            ---@diagnostic disable-next-line: undefined-field
            local port = (config.connect or config).port
            ---@diagnostic disable-next-line: undefined-field
            local host = (config.connect or config).host or "127.0.0.1"
            cb({
              type = "server",
              port = assert(port, "`connect.port` is required for a python `attach` configuration"),
              host = host,
              options = { source_filetype = "python" },
            })
          else
            local python = require("utils.platform").debugpy_python()
            if not python then
              vim.notify("debugpy is not installed; run :ConfigToolsInstall", vim.log.levels.ERROR)
              return
            end
            cb({
              type = "executable",
              command = python,
              args = { "-m", "debugpy.adapter" },
              options = { source_filetype = "python" },
            })
          end
        end,
      },
      configurations = {
        python = {
          {
            type = "python",
            request = "launch",
            name = "[Python] Launch file",
            program = "${file}",
            pythonPath = function()
              return require("languages.python.interpreter").current()
            end,
            env = function()
              return require("languages.python.interpreter").environment()
            end,
            args = function()
              local args_str = vim.fn.input("Commandline args: ")
              return vim.split(args_str, " ", { plain = true })
            end,
          },
        },
      },
    },
  },
}
