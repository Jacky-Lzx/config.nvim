return {
  servers = { "tinymist" },
  tools = {
    { mason = "typstyle", executable = "typstyle" },
    { mason = "tinymist", executable = "tinymist" },
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
  plugins = {
    {
      "chomosuke/typst-preview.nvim",
      ft = "typst",
      version = "1.*",
      opts = {
        -- Use tinymist installed from Mason
        dependencies_bin = {
          ["tinymist"] = "tinymist",
        },
      },
    },
  },
}
