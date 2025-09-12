return {

  -- Change input method automatically
  -- {
  --   "keaising/im-select.nvim",
  --   lazy = false,
  --   cond = function()
  --     return vim.uv.os_uname().sysname == "Darwin"
  --   end,
  --   opts = {
  --     -- Restore the default input method state when the following events are triggered
  --     set_default_events = { "VimEnter", "InsertLeave", "CmdlineLeave" },
  --   },
  --   config = function(_, opts)
  --     require("im_select").setup(opts)
  --   end,
  -- },
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    event = "BufReadPost",
     -- stylua: ignore
   keys = {
    -- Append/insert for each line of visual selections. Similar to block selection insertion.
    { "mI", function() require("multicursor-nvim").insertVisual() end, mode = "x", desc = "Insert cursors at visual selection" },
    { "mA", function() require("multicursor-nvim").appendVisual() end, mode = "x", desc = "Append cursors at visual selection" },
   },
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      -- Mappings defined in a keymap layer only apply when there are multiple cursors. This lets you have overlapping mappings.
      mc.addKeymapLayer(function(layerSet)
        -- Enable and clear cursors using escape.
        layerSet("n", "<esc>", function()
          mc.clearCursors()
        end)
      end)
    end,
  },

  {
    -- Extende `a`/`i` textobjects
    "echasnovski/mini.ai",
    version = "*",
    event = "BufReadPost",
    config = true,
  },

  {
    "echasnovski/mini.bracketed",
    version = "*",
    event = "BufReadPost",
    keys = {
      {
        "]i",
        function()
          require("mini.bracketed").indent("forward", { change_type = "more" })
        end,
        mode = { "n", "x", "o" },
        desc = "Inner indent forward",
      },
      {
        "[i",
        function()
          require("mini.bracketed").indent("backward", { change_type = "more" })
        end,
        mode = { "n", "x", "o" },
        desc = "Inner indent backward",
      },
      {
        "]o",
        function()
          require("mini.bracketed").indent("forward", { change_type = "less" })
        end,
        mode = { "n", "x", "o" },
        desc = "Outer indent forward",
      },
      {
        "[o",
        function()
          require("mini.bracketed").indent("backward", { change_type = "less" })
        end,
        mode = { "n", "x", "o" },
        desc = "Outer indent backward",
      },
    },
    opts = {
      indent = { suffix = "" },
      oldfile = { suffix = "" },
    },
  },

  {
    "echasnovski/mini.surround",
    version = "*",
    event = "BufReadPost",
    config = true,
    keys = {
      -- Disable the vanilla `s` keybinding
      { "s", "<NOP>", mode = { "n", "x", "o" } },
    },
  },

  {
    "echasnovski/mini.operators",
    version = "*",
    event = "BufReadPost",
    opts = {
      replace = { prefix = "cr" },
    },
  },

  -- {
  --   "echasnovski/mini.pairs",
  --   version = "*",
  --   event = { "InsertEnter" },
  --   config = true,
  -- },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      ignored_next_char = "[%w%.]", -- will ignore alphanumeric and `.` symbol
    },
  },

  {
    "echasnovski/mini.align",
    version = "*",
    event = "BufRead",
    opts = {
      mappings = {
        start = "gA",
        start_with_preview = "ga",
      },
    },
    config = function(_, opts)
      require("mini.align").setup(opts)
    end,
  },

  -- {
  --   "echasnovski/mini.cursorword",
  --   version = false,
  --   event = "BufRead",
  --   config = function()
  --     require("mini.cursorword").setup()
  --   end,
  -- },

  -- {
  --   "kylechui/nvim-surround",
  --   version = "*", -- Use for stability; omit to use `main` branch for the latest features
  --   event = "VeryLazy",
  --   opts = {},
  -- },

  -- {
  --   "cappyzawa/trim.nvim",
  --   event = "BufWritePre",
  --   opts = {},
  -- },

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
    "numToStr/Comment.nvim",
    -- stylua: ignore
    keys = {
      { "<leader>/", function() require("Comment.api").toggle.linewise.current() end,                 mode = "n", desc = "[Comment] Comment current line", },
      { "<leader>/", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", mode = "v", desc = "Comment current line",           },
      -- control + / keymappings
      { "<C-_>",     function() require("Comment.api").toggle.linewise.current() end,                 mode = "n", desc = "[Comment] Comment current line", },
      { "<C-_>",     "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", mode = "v", desc = "Comment current line",           },

    },
    config = function()
      require("Comment").setup()
    end,
  },

  { "wakatime/vim-wakatime", lazy = false },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    event = "BufReadPost",
    -- stylua: ignore
    keys = {
      ---@diagnostic disable-next-line: undefined-field
      { "<leader>st", function() require("snacks").picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME", "BUG", "FIXIT", "HACK", "WARN", "ISSUE"  } }) end, desc = "[TODO] Pick todos (without NOTE)", },
      ---@diagnostic disable-next-line: undefined-field
      { "<leader>sT", function() require("snacks").picker.todo_comments() end, desc = "[TODO] Pick todos (with NOTE)", },
    },
    config = true,
  },

  {
    "ibhagwan/smartyank.nvim",
    event = { "BufWinEnter" },
    opts = {
      highlight = {
        enabled = true, -- highlight yanked text
        higroup = "IncSearch", -- highlight group of yanked text
        timeout = 500, -- timeout for clearing the highlight
      },
      clipboard = {
        enabled = true,
      },
      tmux = {
        enabled = true,
        -- remove `-w` to disable copy to host client's clipboard
        cmd = { "tmux", "set-buffer", "-w" },
      },
      osc52 = {
        enabled = true,
        -- escseq = 'tmux',     -- use tmux escape sequence, only enable if you're using tmux and have issues (see #4)
        ssh_only = true, -- false to OSC52 yank also in local sessions
        silent = true, -- true to disable the "n chars copied" echo
        echo_hl = "Directory", -- highlight group of the OSC52 echo message
      },
    },
  },

  {
    "folke/flash.nvim",
    event = "BufReadPost",
    opts = {
      label = {
        rainbow = {
          enabled = true,
          shade = 1,
        },
      },
      modes = {
        char = {
          enabled = false,
        },
      },
    },
    keys = {
      -- stylua: ignore
      { "<leader>f", mode = { "n", "x", "o" }, function() require("flash").jump() end,                                                                                               desc = "[Flash] Jump"              },
      -- stylua: ignore
      { "<leader>F", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,                                                                                         desc = "[Flash] Treesitter"        },
      -- stylua: ignore
      { "<leader>F", mode = { "o", "x" },      function() require("flash").treesitter_search() end,                                                                                  desc = "[Flash] Treesitter Search" },
      -- stylua: ignore
      { "<c-f>",     mode = { "c" },           function() require("flash").toggle() end,                                                                                             desc = "[Flash] Toggle Search"     },
      {
        "<leader>j",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump({
            search = { mode = "search", max_length = 0 },
            jump = { pos = "end" },
            label = { after = { 0, 0 }, matches = false },
            pattern = "^\\s*\\S\\?", -- match non-whitespace at start plus any character (ignores empty lines)
          })
        end,
        desc = "[Flash] Line jump",
      },
      {
        "<leader>k",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump({
            search = { mode = "search", max_length = 0 },
            jump = { pos = "end" },
            label = { after = { 0, 0 }, matches = false },
            pattern = "^\\s*\\S\\?", -- match non-whitespace at start plus any character (ignores empty lines)
          })
        end,
        desc = "[Flash] Line jump",
      },
    },
  },

  {
    "bullets-vim/bullets.vim",

    config = function()
      vim.g.bullets_set_mappings = 0 -- disable adding default key mappings, default = 1
      vim.g.bullets_custom_mappings = {
        { "imap", "<cr>", "<Plug>(bullets-newline)" },
      }
    end,
  },
}
