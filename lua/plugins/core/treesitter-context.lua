return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    enabled = false,
    event = "BufReadPost",
    opts = {
      -- Enable this plugin (Can be enabled/disabled later via commands)
      enable = true,
      -- Enable multiwindow support.
      multiwindow = true,
      -- How many lines the window should span. Values <= 0 mean no limit.
      -- Can be '<int>%' like '30%' - to specify percentage of win.height
      max_lines = 5,
      -- Minimum editor window height to enable context. Values <= 0 mean no limit.
      min_window_height = 0,
      -- Whether to show line numbers
      line_numbers = true,
      -- Maximum number of lines to show for a single context
      multiline_threshold = 20,
      -- Line used to calculate context. Choices: 'cursor', 'topline'
      mode = "cursor",
      -- Separator between context and content. Should be a single character string, like '-'.
      -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
      separator = "─",
    },
    -- stylua: ignore
    keys = {
      { "[C", function() require("treesitter-context").go_to_context(vim.v.count1) end, mode = { "n" }, desc = "TS go to context", silent = true, },
    },
    config = function(_, opts)
      require("treesitter-context").setup(opts)

      local ts_context = require("treesitter-context")

      require("snacks")
        .toggle({
          name = "Treesitter Context",
          get = function()
            return ts_context.enabled()
          end,
          set = function(enabled)
            if enabled then
              ts_context.enable()
            else
              ts_context.disable()
            end
          end,
        })
        :map("<leader>tC")
    end,
  },

  -- {
  --   "nvim-treesitter/nvim-tree-docs",
  --   keys = {
  --     { "gdd" },
  --   },
  --   opts = {
  --     tree_docs = {
  --       enable = true,
  --     },
  --   },
  --   config = function(_, opts)
  --     require("nvim-treesitter.configs").setup(opts)
  --   end,
  -- },

  -- TODO
  -- {
  --   "nvim-treesitter/nvim-treesitter-refactor",
  --
  --   opts = {
  --     refactor = {
  --       highlight_definitions = {
  --         enable = true,
  --         -- Set to false if you have an `updatetime` of ~100.
  --         clear_on_cursor_move = true,
  --       },
  --       smart_rename = {
  --         enable = true,
  --         -- Assign keymaps to false to disable them, e.g. `smart_rename = false`.
  --         keymaps = {
  --           smart_rename = "grr",
  --         },
  --       },
  --       highlight_current_scope = {
  --         -- enable = true,
  --       },
  --     },
  --   },
  --
  --   config = function(_, opts)
  --     require("nvim-treesitter.configs").setup(opts)
  --   end,
  -- },
  -- { "nvim-treesitter/nvim-treesitter-textobjects" },
}
