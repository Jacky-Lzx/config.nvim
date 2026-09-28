local html_beautify = require("config.platform").executable("html_beautify")

return {
  servers = { "superhtml" },
  tools = {
    { mason = "superhtml", executable = "superhtml" },
    { executable = "html_beautify" },
  },
  parsers = { "html" },
  formatters = {
    -- Should install js-beautify first `https://github.com/beautifier/js-beautify`
    html = html_beautify and { "html_beautify" } or nil,
  },
}
