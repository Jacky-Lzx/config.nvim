return {
  servers = { "cmake" },
  tools = {
    { package = "cmakelang", executable = "cmake-format" },
    { package = "cmake-language-server", executable = "cmake-language-server" },
  },
  parsers = { "cmake" },
  formatters = {
    cmake = { "cmake_format" }, -- From managed package "cmakelang"
  },
}
