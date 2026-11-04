local root = require("utils.platform").dev_plugin_root()

return {
  {
    dir = root .. "/file-tools.nvim",
    name = "file-tools.nvim",
    main = "file_tools",
    cmd = "FileTools",
    dependencies = { "theme-tools.nvim" },
    opts = { tree = { width = 40, follow = true } },
    keys = {
      { "<leader>e", "<Cmd>FileTools toggle<CR>", desc = "[Files] Toggle tree" },
      { "<leader>E", "<Cmd>FileTools find<CR>", desc = "[Files] Reveal current file" },
      {
        "<leader>cw",
        function()
          require("file_tools").open({ root = vim.fn.getcwd() })
        end,
        desc = "[Files] Open working directory",
      },
    },
  },
}
