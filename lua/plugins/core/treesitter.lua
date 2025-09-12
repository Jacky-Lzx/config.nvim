return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      auto_install = true,
      highlight = {
        enable = true,
        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enabale = true,
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
      max_lines = 5, -- How many lines the window should span. Values <= 0 mean no limit.
      min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
      line_numbers = true,
      multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
      trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
      -- Separator between context and content. Should be a single character string, like '-'.
      -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
      -- separator = nil,
      separator = "─",
      zindex = 20, -- The Z-index of the context window
    },
    -- stylua: ignore
    keys = {
      { "[c", function() require("treesitter-context").go_to_context(vim.v.count1) end, mode = { "n" }, desc = "TS go to context", silent = true, },
    },
    config = function(_, opts)
      local configs = require("treesitter-context")

      -- vim.keymap.set("n", "[c", function()
      --   require("treesitter-context").go_to_context(vim.v.count1)
      -- end, { silent = true })

      configs.setup(opts)
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
