return {
  servers = { "clangd" },
  tools = {
    { package = "clangd", executable = "clangd" },
    { package = "codelldb", executable = "codelldb", feature = "debugging" },
    { executable = "clang-format" },
  },
  parsers = { "cpp", "c", "cuda" },
  formatters = {
    c = { "clang-format" },
    cpp = { "clang-format" },
    cuda = { "clang-format" },
  },
  plugins = { { import = "languages.cpp.plugins" } },
}
