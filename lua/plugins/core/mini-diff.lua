return {
  {
    "echasnovski/mini.diff",
    event = "BufReadPost",
    version = "*",
    -- stylua: ignore
    keys = {
      { "<leader>to", function() require("mini.diff").toggle_overlay(vim.api.nvim_get_current_buf()) end, mode = "n", desc = "[Mini.Diff] Toggle diff overlay", },
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
