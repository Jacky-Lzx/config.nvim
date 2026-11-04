return {
  servers = { "gdscript" },
  tools = {
    { package = "gdscript-formatter", executable = "gdscript-formatter" },
    { package = "gdtoolkit", executable = "gdlint" },
    { executable = "gdformat" },
  },
  parsers = { "gdscript", "godot_resource" },
  linters = {
    gdscript = { "gdlint" },
  },
  formatters = {
    gdscript = { "gdscript-formatter" },
  },
}
