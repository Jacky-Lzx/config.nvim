return {
  {
    dir = require("utils.platform").dev_plugin_root() .. "/debug-tools.nvim",
    name = "debug-tools.nvim",
    main = "debug_tools",
    lazy = false,
    priority = 1000,
    opts = { globals = true, override_print = true },
  },
}
