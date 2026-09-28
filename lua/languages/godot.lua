return {
  servers = { "gdscript" },
  tools = {
    { mason = "gdscript-formatter", executable = "gdscript-formatter" },
    { mason = "gdtoolkit", executable = "gdlint" },
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
