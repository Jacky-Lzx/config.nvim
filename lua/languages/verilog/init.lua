return {
  servers = { "verible" },
  tools = {
    { mason = "verible", executable = "verible-verilog-ls" },
    { executable = "verible-verilog-format" },
    { executable = "iverilog" },
  },
  parsers = { "systemverilog" },
  formatters = {
    verilog = { "verible-verilog-format" },
    systemverilog = { "verible-verilog-format" },
  },
  formatter_options = {
    ["verible-verilog-format"] = {
      command = "verible-verilog-format",
      args = { "-" },
    },
  },
  linters = { verilog = { "iverilog" }, systemverilog = { "iverilog" } },
  plugins = { { import = "languages.verilog.plugins" } },
}
