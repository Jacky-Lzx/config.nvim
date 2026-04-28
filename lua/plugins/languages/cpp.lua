local M = {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = {
      ensure_installed = { "cpp", "c" },
    },
    opts_extend = { "ensure_installed" },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "clangd", "codelldb" } },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
        cuda = { "clang-format" },
      },
    },
  },

  {
    "mfussenegger/nvim-dap",
    ft = { "c", "cpp" },
    optional = true,
    opts = function()
      local dap = require("dap")

      -- See `https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation`
      dap.adapters.codelldb = {
        name = "codelldb",
        type = "executable",
        command = "codelldb", -- or if not in $PATH: "/absolute/path/to/codelldb"

        -- On windows you may have to uncomment this:
        -- detached = false,
      }
      dap.configurations.cpp = {
        {
          name = "[C/C++] Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          -- You can also dynamically get arguments, e.g., from user input:
          args = function()
            local args_str = vim.fn.input("Commandline args: ")
            return vim.split(args_str, " ", { plain = true })
          end,
        },
      }
      dap.configurations.c = dap.configurations.cpp
    end,
  },
}

return M
