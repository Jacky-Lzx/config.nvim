return {
  {
    "echasnovski/mini.diff",
    version = "*",
    keys = {
      {
        "<leader>to",
        function()
          local diff, buf = require("mini.diff"), vim.api.nvim_get_current_buf()
          -- Setup's auto-enable is scheduled; enable before the first key replay.
          diff.enable(buf)
          if diff.get_buf_data(buf) then
            diff.toggle_overlay(buf)
          end
        end,
        mode = "n",
        desc = "[Mini.Diff] Toggle diff overlay",
      },
    },
    opts = {
      -- Module mappings. Use `''` (empty string) to disable one.
      -- NOTE: Mappings are handled by gitsigns.
      mappings = {
        -- Apply hunks inside a visual/operator region
        apply = "",
        -- Reset hunks inside a visual/operator region
        reset = "",
        -- Hunk range textobject to be used inside operator
        -- Works also in Visual mode if mapping differs from apply and reset
        textobject = "",
        -- Go to hunk range in corresponding direction
        goto_first = "",
        goto_prev = "",
        goto_next = "",
        goto_last = "",
      },
    },
  },
}
