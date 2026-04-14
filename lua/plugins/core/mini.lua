return {

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
      -- stylua: ignore
    keys = {
      { "]i",    function() require("mini.bracketed").indent("forward",  { change_type = "more" }) end, mode = { "n", "x", "o" }, desc = "Inner indent forward",      },
      { "[i",    function() require("mini.bracketed").indent("backward", { change_type = "more" }) end, mode = { "n", "x", "o" }, desc = "Inner indent backward",     },
      { "]o",    function() require("mini.bracketed").indent("forward",  { change_type = "less" }) end, mode = { "n", "x", "o" }, desc = "Outer indent forward",      },
      { "[o",    function() require("mini.bracketed").indent("backward", { change_type = "less" }) end, mode = { "n", "x", "o" }, desc = "Outer indent backward",     },
      { "<A-j>", function() MiniBracketed.diagnostic("forward") end,                                    mode = { "n" },           desc = "Go to next diagnostic",     },
      { "<A-k>", function() MiniBracketed.diagnostic("backward") end,                                   mode = { "n" },           desc = "Go to previous diagnostic", },
    },
    opts = {
      indent = { suffix = "" },
      oldfile = { suffix = "" },
      conflict = { suffix = "" },
      comment = { suffix = "" },
    },
  },

  {
    "echasnovski/mini.surround",
    version = "*",
    event = "BufReadPost",
    keys = {
      -- Disable the vanilla `s` keybinding
      { "s", "<NOP>", mode = { "n", "x", "o" } },
      { "sa", mode = { "n", "x", "o" } },
      { "sr", mode = { "n", "x", "o" } },
      { "sd", mode = { "n", "x", "o" } },
    },
    config = true,
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

  {
    "echasnovski/mini.comment",
    opts = {
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Toggle comment (like `gcip` - comment inner paragraph) for both
        -- Normal and Visual modes
        comment = "gc",

        -- Toggle comment on current line
        comment_line = "<leader>/",

        -- Toggle comment on visual selection
        comment_visual = "<leader>/",

        -- Define 'comment' textobject (like `dgc` - delete whole comment block)
        -- Works also in Visual mode if mapping differs from `comment_visual`
        textobject = "gc",
      },
    },
  },
}
