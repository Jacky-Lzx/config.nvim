-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

local lazy_opts = {
  git = {
    clone_timeout = 600,
    -- url_format = "git@github.com:%s.git",
  },
}

require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      transparent_background = true,
      float = {
        transparent = true, -- enable transparent floating windows
      },
      flavour = "mocha",
      integrations = {
        flash = true,
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
            ok = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
            ok = { "underline" },
          },
          inlay_hints = {
            background = true,
          },
        },
        nvim_surround = true,
        treesitter = true,
      },
      custom_highlights = function(colors)
          -- stylua: ignore
          return {
            LineNr                      = { fg = colors.surface2 },
            Visual                      = { bg = colors.overlay0 },
            Search                      = { bg = colors.surface2 },
            IncSearch                   = { bg = colors.mauve },
            CurSearch                   = { bg = colors.mauve },
            LspSignatureActiveParameter = { bg = colors.overlay0 },
            MatchParen                  = { bg = colors.mauve, fg = colors.base, bold = true},
          }
      end,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)

      -- vim.cmd([[colorscheme catppuccin-mocha]])
      vim.cmd.colorscheme("catppuccin-nvim")
    end,
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
  {
    "numToStr/Comment.nvim",
    enabled = false,
    -- stylua: ignore
    keys = {
      { "<leader>/", function() require("Comment.api").toggle.linewise.current() end,                 mode = "n", desc = "[Comment] Comment current line", },
      { "<leader>/", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", mode = "v", desc = "Comment current line",           },
      -- control + / keymappings
      { "<C-_>",     function() require("Comment.api").toggle.linewise.current() end,                 mode = "n", desc = "[Comment] Comment current line", },
      { "<C-_>",     "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", mode = "v", desc = "Comment current line",           },
    },
    config = true,
  },
  {
    "ibhagwan/smartyank.nvim",
    opts = {
      highlight = {
        enabled = true, -- highlight yanked text
        higroup = "IncSearch", -- highlight group of yanked text
        timeout = 400, -- timeout for clearing the highlight
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
        silent = false, -- true to disable the "n chars copied" echo
        echo_hl = "Directory", -- highlight group of the OSC52 echo message
      },
    },
  },
}, lazy_opts)
