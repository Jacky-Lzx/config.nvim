return {
  servers = { "texlab" },
  tools = {
    { mason = "tex-fmt", executable = "tex-fmt" },
    { mason = "texlab", executable = "texlab" },
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
      prepend_args = { "--config", vim.fn.stdpath("config") .. "/configs/tex-fmt.toml" },
    },
    latexindent = {
      prepend_args = { "--local", vim.fn.stdpath("config") .. "/configs/latexindent.yaml" },
    },
  },
  linters = { tex = { "chktex" } },
  linter_options = {
    chktex = {
          -- stylua: ignore
          args = {
            "-wall", "-q", "-n1", "-n3", "-n8", "-n9", "-n22", "-n30", "-n24", "-n17", "-e16",
            "-v0", "-I0", "-s", ":", "-f", "%l%b%c%b%d%b%k%b%n%b%m%b%b%b",
          },
      ignore_exitcode = true,
    },
  },
  plugins = { { import = "languages.latex.plugins" } },
}
