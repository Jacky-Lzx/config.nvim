vim.lsp.enable("rust_analyzer")

local M = {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = {
      ensure_installed = { "rust", "toml" },
    },
    opts_extend = { "ensure_installed" },
  },

  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        crates = {
          enabled = true,
        },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "codelldb", "rust-analyzer" } },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt", lsp_format = "fallback" },
      },
    },
  },

  {
    "mfussenegger/nvim-dap",
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

      dap.configurations.rust = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            -- Build the project before starting a debug session
            vim.fn.system("cargo build")

            -- Get the file name of the target executable
            local metadata_json = vim.fn.system("cargo metadata --format-version 1 --no-deps")
            local metadata = vim.fn.json_decode(metadata_json)
            local target_name = metadata.packages[1].targets[1].name
            local target_dir = metadata.target_directory
            return target_dir .. "/debug/" .. target_name
          end,
          args = function()
            -- Command line arguments that will be passed to the program
            local inputstr = vim.fn.input("CommandLine args: ", "")
            local params = {}
            for param in string.gmatch(inputstr, "[^%s]+") do
              table.insert(params, param)
            end
            return params
          end,
        },
      }
    end,
  },
}

return M
