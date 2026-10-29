return {
  servers = { "texquill" },
  tools = {
    { mason = "tex-fmt", executable = "tex-fmt" },
    {
      executable = "texquill",
      resolve = function()
        return require("languages.latex.lsp").executable()
      end,
    },
    { executable = "chktex" },
    { executable = "latexmk" },
    { executable = "tectonic" },
  },
  parsers = { "latex", "bibtex" },
  formatters = {
    tex = { "tex-fmt" },
    -- tex = { "latexindent" },
    -- The tex-fmt for bib cannot align the entries, or add additional spaces around `=`
    bib = { "tex-fmt" },
  },
  formatter_options = {
    ["tex-fmt"] = {
      prepend_args = { "--config", require("utils.paths").config("configs", "tex-fmt.toml") },
    },
    latexindent = {
      prepend_args = { "--local", require("utils.paths").config("configs", "latexindent.yaml") },
    },
  },
  plugins = { { import = "languages.latex.plugins" } },
}
