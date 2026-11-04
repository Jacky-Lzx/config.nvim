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
  plugins = {
    {
      "chomosuke/typst-preview.nvim",
      ft = "typst",
      version = "1.*",
      opts = {
        -- Use tinymist installed by toolchain
        dependencies_bin = {
          ["tinymist"] = "tinymist",
        },
      },
    },
  },
}
