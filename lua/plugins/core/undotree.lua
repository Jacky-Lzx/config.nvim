return {
  {
    "mbbill/undotree",
    keys = {
      { "<leader>ut", "<cmd>UndotreeToggle<cr>", desc = "Toggle undo-tree" },
    },
    init = function()
      vim.cmd([[
      if has("persistent_undo")
         let target_path = expand('~/.undodir')

          " create the directory and any parent directories
          " if the location does not exist.
          if !isdirectory(target_path)
              call mkdir(target_path, "p", 0700)
          endif

          let &undodir=target_path
          set undofile
      endif
      ]])
    end,
  },

  {
    "romgrk/barbar.nvim",
    optional = true,
    opts = {
      -- Set the filetypes which barbar will offset itself for
      sidebar_filetypes = {
        undotree = { text = "UndoTree", align = "center" },
      },
    },
  },
}
