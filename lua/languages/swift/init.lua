local platform = require("config.platform")

return {
  servers = { "sourcekit" },
  tools = platform.is("macos") and {
    { executable = "swift" },
    { executable = "xcrun" },
    { executable = "swiftlint" },
    { executable = "xcode-build-server" },
  } or {
    { executable = "swift" },
    { executable = "sourcekit-lsp" },
    { executable = "swiftlint" },
    { executable = "lldb-dap", feature = "debugging" },
  },
  parsers = { "swift" },
  formatters = { swift = { "swift" } },
  linters = { swift = { "swiftlint" } },
  plugins = { { import = "languages.swift.plugins" } },
}
