-- Verilog related plugins

vim.lsp.config("verible", {
  -- cmd = { "verible-verilog-ls", "--rules_config_search" },

  -- root_dir = function(fname)
  --   -- return vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
  --   -- print(vim.fs.dirname(fname))
  --   return vim.fs.dirname(fname)
  -- end,

  -- root_dir = function(fname)
  --   return vim.fs.dirname(vim.fn.getcwd())
  -- end,
})

vim.lsp.enable("verible")

local M = {
  {
    "nvim-treesitter/nvim-treesitter",
    opts_extend = { "ensure_installed", "highlight.disable" },
    opts = {
      ensure_installed = { "verilog" },
      highlight = {
        disable = { "verilog", "systemverilog" },
      },
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
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.verilog = { "iverilog" }

      local verilator = require("lint").linters.verilator
      verilator.args = {
        "+1800-2017ext+sv",
      }

      local pattern = "(.-):(%d+): ([%w ]+): (.*)"
      local groups = { "file", "lnum", "severity", "message" }
      local severities = {
        ["error"] = vim.diagnostic.severity.ERROR,
        ["warning"] = vim.diagnostic.severity.WARN,
        ["     "] = vim.diagnostic.severity.INFO,
        ["       "] = vim.diagnostic.severity.INFO,
      }

      require("lint").linters.iverilog = {
        name = "iverilog",
        cmd = "iverilog",
        stdin = false, -- or false if it doesn't support content input via stdin. In that case the filename is automatically added to the arguments.
        append_fname = true, -- Automatically append the file name to `args` if `stdin = false` (default: true)
        args = {
          "-g2012",
          "-Wall",
          "-y",
          ".",
          "-o",
          "/dev/null",
        }, -- list of arguments. Can contain functions with zero arguments that will be evaluated once the linter is used.
        stream = "both", -- ('stdout' | 'stderr' | 'both') configure the stream to which the linter outputs the linting result.
        ignore_exitcode = true, -- set this to true if the linter exits with a code != 0 and that's considered normal.
        env = nil, -- custom environment table to use with the external process. Note that this replaces the *entire* environment, it is not additive.
        parser = require("lint.parser").from_pattern(pattern, groups, severities, { ["source"] = "iverilog" }),
      }
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

return M
