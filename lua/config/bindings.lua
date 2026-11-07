-- Pure optional library: available before manager startup without activating UI.
return require("config.plugin_bootstrap")
  .library("keymap-tools.nvim", "keymap_tools.bindings")
  .new({ group_prefix = "ConfigBindings_" })
