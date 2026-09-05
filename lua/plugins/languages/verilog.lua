return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = { "systemverilog" },
    },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "verible" } },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        verilog = { "verible-verilog-format" },
      },
      formatters = {
        ["verible-verilog-format"] = {
          command = "verible-verilog-format",
          args = { "-" },
        },
      },
    },
  },

  -- linter
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      local pattern = "(.-):(%d+): ([%w ]+): (.*)"
      local groups = { "file", "lnum", "severity", "message" }
      local severities = {
        ["error"] = vim.diagnostic.severity.ERROR,
        ["warning"] = vim.diagnostic.severity.WARN,
        ["     "] = vim.diagnostic.severity.INFO,
        ["       "] = vim.diagnostic.severity.INFO,
      }

      opts.linters_by_ft = vim.tbl_deep_extend("force", opts.linters_by_ft or {}, { verilog = { "iverilog" } })
      opts.linters = vim.tbl_deep_extend("force", opts.linters or {}, {
        iverilog = {
          name = "iverilog",
          cmd = "iverilog",
          stdin = false,
          append_fname = true,
          args = { "-g2012", "-Wall", "-y", ".", "-o", "/dev/null" },
          stream = "both",
          ignore_exitcode = true,
          parser = require("lint.parser").from_pattern(pattern, groups, severities, { source = "iverilog" }),
        },
      })
      return opts
    end,
  },

  -- {'HonkW93/automatic-verilog'},
  -- {
  --   "mingo99/verilog-autoinst.nvim",
  --   file_type = { "verilog", "systemverilog" },
  --   cmd = "AutoInst",
  --   keys = {
  --     { "<leader>fv", "<cmd>AutoInst<cr>", desc = "Automatic instantiation for verilog" }
  --   },
  --   dependencies = { "nvim-telescope/telescope.nvim" },
  --   opts = {},
  -- },
}
