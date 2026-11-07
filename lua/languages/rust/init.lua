return {
  servers = { "rust_analyzer" },
  tools = {
    { package = "codelldb", executable = "codelldb", feature = "debugging" },
    { package = "rust-analyzer", executable = "rust-analyzer" },
    { executable = "rustfmt" },
    { executable = "cargo" },
  },
  parsers = { "rust", "toml" },
  formatters = {
    rust = { "rustfmt", lsp_format = "fallback" },
  },
  plugins = { "languages.rust.crates", "languages.rust.debug" },
}
