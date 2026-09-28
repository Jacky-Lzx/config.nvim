return {
  servers = { "rust_analyzer" },
  tools = {
    { mason = "codelldb", executable = "codelldb", feature = "debugging" },
    { mason = "rust-analyzer", executable = "rust-analyzer" },
    { executable = "rustfmt" },
    { executable = "cargo" },
  },
  parsers = { "rust", "toml" },
  formatters = {
    rust = { "rustfmt", lsp_format = "fallback" },
  },
  plugins = { { import = "languages.rust.plugins" } },
}
