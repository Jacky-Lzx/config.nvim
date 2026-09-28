return {
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
}
