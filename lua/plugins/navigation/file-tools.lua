local root = require("utils.platform").dev_plugin_root()

return {
  {
    dir = root .. "/file-tools.nvim",
    name = "file-tools.nvim",
    main = "file_tools",
    cmd = "FileTools",
    dependencies = { "theme-tools.nvim" },
    opts = { tree = { width = 40, follow = true } },
    init = function()
      local unsupported = {
        "<A-h>",
        "<A-l>",
        "[b",
        "]b",
        "<A-w>",
        "<A-u>",
        "<A-S-,>",
        "<A-S-.>",
        "<A-<>",
        "<A->>",
      }
      for index = 1, 9 do
        unsupported[#unsupported + 1] = "<A-" .. index .. ">"
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ConfigFileToolsKeys", { clear = true }),
        pattern = "file-tools",
        callback = function(event)
          -- Files is a fixed sidebar; buffer actions belong to editing buffers.
          for _, key in ipairs(unsupported) do
            vim.keymap.set("n", key, "<Nop>", {
              buffer = event.buf,
              silent = true,
              nowait = true,
              desc = "Files: buffer action unavailable",
            })
          end
        end,
      })
    end,
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
