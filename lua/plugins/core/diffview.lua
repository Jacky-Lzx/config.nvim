return {
  -- NOTE: The original repo `https://github.com/sindrets/diffview.nvim` is not active anymore.
  --       Use the forked repo. <2026.04.14, lzx>
  {
    "dlyongemallo/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      {
        "<leader>Dt",
        function()
          -- Get all currently active views
          local views = require("diffview.lib").views
          if next(views) == nil then
            -- No view open, so open it
            vim.cmd("DiffviewOpen")
          else
            -- View is open, close it
            vim.cmd("DiffviewClose")
          end
        end,
        desc = "Toggle Diffview",
      },
    },
    opts = {
      enhanced_diff_hl = false,
      watch_index = false,
      view = {
        default = {
          layout = "diff2_vertical",
        },
        merge_tool = {
          layout = "diff3_vertical",
        },
        file_history = {
          layout = "diff2_vertical",
        },
      },
    },
  },
}
