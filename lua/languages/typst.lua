return {
  servers = { "tinymist" },
  tools = {
    { package = "typstyle", executable = "typstyle" },
    { package = "tinymist", executable = "tinymist" },
  },
  parsers = { "typst" },
  formatters = {
    typst = { "typstyle" },
  },
  formatter_options = {
    typstyle = {
      prepend_args = { "-l", "120", "--wrap-text" },
    },
  },
}
