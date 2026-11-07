return {
  {
    id = "bigfile-tools.nvim",
    source = "Jacky-Lzx/bigfile-tools.nvim",
    version = "main",
    dev = true,
    main = "bigfile_tools",
    opts = require("features.files").options(),
  },
}
