return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = {
      ensure_installed = { "python" },
    },
    opts_extend = { "ensure_installed" },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts = {
      ensure_installed = { "ruff", "pyright", "basedpyright", "debugpy" },
    },
    opts_extend = { "ensure_installed" },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
      },
    },
  },

  -- linter
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        python = { "ruff" },
      },
    },
  },

  {
    "linux-cultist/venv-selector.nvim",
    --  Call config for python files and load the cached venv automatically
    ft = "python",
    cmd = "VenvSelect",
    keys = { { "<leader>cv", "<CMD>VenvSelect<CR>", desc = "Select VirtualEnv", ft = "python" } },
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
      },
    },
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
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
            local python = require("config.platform").debugpy_python()
            if not python then
              vim.notify("debugpy is not installed; run :MasonToolsInstall", vim.log.levels.ERROR)
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
