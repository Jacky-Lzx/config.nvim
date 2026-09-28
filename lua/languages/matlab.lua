return {
  servers = { "matlab_ls" },
  tools = {
    { mason = "matlab-language-server", executable = "matlab-language-server" },
    { mason = "miss_hit", executable = "mh_style" },
  },
  parsers = { "matlab" },
  formatters = {
    matlab = { "mh_style" },
  },
}
