return {
  servers = { "basedpyright" },
  tools = {
    { mason = "ruff", executable = "ruff" },
    { mason = "basedpyright", executable = "basedpyright" },
    {
      mason = "debugpy",
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
  plugins = { { import = "languages.python.plugins" } },
}
