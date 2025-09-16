return {
  {
    "rmagatti/auto-session",
    lazy = false,

    -- stylua: ignore
    keys = {
      { "<leader>ps", "<CMD>AutoSession restore<CR>", desc = "[Auto Session] Restore session" },
      { "<leader>pS", "<CMD>AutoSession search<CR>",  desc = "[Auto Session] Search session"  },
      { "<leader>pD", "<CMD>AutoSession delete<CR>",  desc = "[Auto Session] Delete session"  },
    },

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      auto_restore = false,
      suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
      -- Do not load the session if there's an error
      continue_restore_on_error = false,
      -- Buffers with matching filetypes will be closed before saving
      close_filetypes_on_save = { "checkhealth" },
    },

    init = function()
      -- vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
      vim.o.sessionoptions = "buffers,curdir,folds,tabpages,winsize,winpos,localoptions"
    end,
  },
}
