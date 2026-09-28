return {
  servers = { "clangd" },
  tools = {
    { mason = "clangd", executable = "clangd" },
    { mason = "codelldb", executable = "codelldb", feature = "debugging" },
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
