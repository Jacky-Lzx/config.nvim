local has_fish = require("config.platform").executable("fish") ~= nil

return {
  servers = { "bashls" },
  tools = {
    { mason = "shfmt", executable = "shfmt" },
    { mason = "bash-language-server", executable = "bash-language-server" },
    { executable = "fish" },
  },
  parsers = { "bash" },
  formatters = {
    sh = { "shfmt" },
    fish = has_fish and { "fish_indent" } or nil,
  },
  linters = {
    fish = has_fish and { "fish" } or nil,
    bash = { "bash" },
  },
}
