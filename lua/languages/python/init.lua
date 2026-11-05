return {
  servers = { "basedpyright" },
  tools = {
    { package = "ruff", executable = "ruff" },
    { package = "basedpyright", executable = "basedpyright" },
    {
      package = "debugpy",
      resolve = function()
        return require("utils.platform").debugpy_python()
      end,
      feature = "debugging",
    },
  },
  parsers = { "python" },
  formatters = {
    python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
  },
  linters = {
    python = { "ruff" },
  },
  plugins = { "languages.python.plugins" },
}
