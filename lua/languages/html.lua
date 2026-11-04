return {
  servers = { "superhtml" },
  tools = {
    { package = "superhtml", executable = "superhtml" },
    { executable = "html_beautify", optional = true },
  },
  parsers = { "html" },
  formatters = {
    -- Should install js-beautify first `https://github.com/beautifier/js-beautify`
    html = { "html_beautify" },
  },
  requires = { formatters = { html = "html_beautify" } },
}
