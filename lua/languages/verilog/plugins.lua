local parser
return {
  {
    id = "nvim-lint",
    opts = {
      linters = {
        iverilog = {
          name = "iverilog",
          cmd = "iverilog",
          stdin = false,
          append_fname = true,
          args = { "-g2012", "-Wall", "-y", ".", "-o", "/dev/null" },
          stream = "both",
          ignore_exitcode = true,
          parser = function(...)
            if not parser then
              parser = require("lint.parser").from_pattern(
                "(.-):(%d+): ([%w ]+): (.*)",
                { "file", "lnum", "severity", "message" },
                {
                  error = vim.diagnostic.severity.ERROR,
                  warning = vim.diagnostic.severity.WARN,
                  ["     "] = vim.diagnostic.severity.INFO,
                  ["       "] = vim.diagnostic.severity.INFO,
                },
                { source = "iverilog" }
              )
            end
            return parser(...)
          end,
        },
      },
    },
  },
}
