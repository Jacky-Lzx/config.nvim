return {
  {
    "copilotlsp-nvim/copilot-lsp",
    event = "VeryLazy",
    keys = {
      {
        "<leader>cn",
        function()
          local bufnr = vim.api.nvim_get_current_buf()
          local state = vim.b[bufnr].nes_state
          if state then
            -- Try to jump to the start of the suggestion edit.
            -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
            local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
              or (require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit())
            return nil
            -- else
            --   -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
            --   return "<C-i>"
          end
        end,
        desc = "Accept Copilot NES suggestion",
      },
      {
        "<C-i>",
        mode = { "s", "i" },
        function()
          local bufnr = vim.api.nvim_get_current_buf()
          local state = vim.b[bufnr].nes_state
          if state then
            -- Try to jump to the start of the suggestion edit.
            -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
            local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
              or (require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit())
            return nil
            -- else
            --   -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
            --   return "<C-i>"
          end
        end,
        desc = "Accept Copilot NES suggestion",
      },
    },
    init = function()
      vim.g.copilot_nes_debounce = 500
    end,
    opts = {
      nes = {
        move_count_threshold = 3, -- Clear after 5 cursor movements
      },
    },
  },
}
