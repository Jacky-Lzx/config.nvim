return {
  servers = { "cmake" },
  tools = {
    { mason = "cmakelang", executable = "cmake-format" },
    { mason = "cmake-language-server", executable = "cmake-language-server" },
  },
  parsers = { "cmake" },
  formatters = {
    cmake = { "cmake_format" }, -- From Mason package "cmakelang"
  },
}
