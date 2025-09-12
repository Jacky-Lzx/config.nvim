return {
  {
    "j-hui/fidget.nvim",
    opts = {
      notification = {
        window = {
          winblend = 0,
          border = "rounded",
        },
      },
    },
  },

  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>e", "<CMD>NvimTreeToggle<CR>", mode = { "n" }, desc = "[NvimTree] Toggle NvimTree" },
    },
    opts = {
      update_focused_file = {
        enable = true,
      },
    },
  },

  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "BufReadPost",
    submodules = false,
    config = true,
    main = "rainbow-delimiters.setup",
  },

  -- {
  --   "lukas-reineke/indent-blankline.nvim",
  --   dependencies = {
  --     "HiPhish/rainbow-delimiters.nvim",
  --   },
  --   main = "ibl",
  --   event = "BufReadPost",
  --   opts = {
  --     scope = {},
  --   },
  --   config = function(_, opts)
  --     local highlight = {
  --       "RainbowYellow",
  --       "RainbowGreen",
  --       "RainbowOrange",
  --       "RainbowViolet",
  --       "RainbowPink",
  --       "RainbowRosewater",
  --       "RainbowRed",
  --     }
  --     local hooks = require("ibl.hooks")
  --     -- create the highlight groups in the highlight setup hook, so they are reset
  --     -- every time the colorscheme changes
  --     -- stylua: ignore
  --     hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
  --       vim.api.nvim_set_hl(0, "RainbowYellow",    { fg = "#f9e2af" })
  --       vim.api.nvim_set_hl(0, "RainbowGreen",     { fg = "#a6e3a1" })
  --       vim.api.nvim_set_hl(0, "RainbowOrange",    { fg = "#fab387" })
  --       vim.api.nvim_set_hl(0, "RainbowViolet",    { fg = "#cba6f7" })
  --       vim.api.nvim_set_hl(0, "RainbowPink",      { fg = "#f5c2e7" })
  --       vim.api.nvim_set_hl(0, "RainbowRosewater", { fg = "#f5e0dc" })
  --       vim.api.nvim_set_hl(0, "RainbowRed",       { fg = "#f38ba8" })
  --     end)
  --
  --     vim.g.rainbow_delimiters = { highlight = highlight }
  --     opts.scope.highlight = highlight
  --     require("ibl").setup(opts)
  --
  --     hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
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

  -- Show colors in the text: e.g. "#b3e2a7"
  {
    "norcalli/nvim-colorizer.lua",
    event = "BufRead",
    opts = {},
    config = function(_)
      require("colorizer").setup()
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPost",
    opts = {
      signcolumn = false,
      numhl = true,
      -- word_diff = true,
      current_line_blame = true,
      attach_to_untracked = true,
      preview_config = {
        border = "rounded",
      },
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        -- stylua: ignore
        map("n", "]h", function() if vim.wo.diff then vim.cmd.normal({ "]h", bang = true }) else gitsigns.nav_hunk("next") end end, { desc = "[Git] Next hunk" })
        -- stylua: ignore
        map("n", "]H", function() if vim.wo.diff then vim.cmd.normal({ "]H", bang = true }) else gitsigns.nav_hunk("last") end end, { desc = "[Git] Last hunk" })
        -- stylua: ignore
        map("n", "[h", function() if vim.wo.diff then vim.cmd.normal({ "[h", bang = true }) else gitsigns.nav_hunk("prev") end end, { desc = "[Git] Prev hunk" })
        -- stylua: ignore
        map("n", "[H", function() if vim.wo.diff then vim.cmd.normal({ "[H", bang = true }) else gitsigns.nav_hunk("first") end end, { desc = "[Git] First hunk" })

        -- Actions
        map("n", "<leader>ggs", gitsigns.stage_hunk, { desc = "[Git] Stage hunk" })
        -- stylua: ignore
        map("v", "<leader>ggs", function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "[Git] Stage hunk (Visual)" })

        map("n", "<leader>ggr", gitsigns.reset_hunk, { desc = "[Git] Reset hunk" })
        -- stylua: ignore
        map("v", "<leader>ggr", function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "[Git] Reset hunk (Visual)" })

        map("n", "<leader>ggS", gitsigns.stage_buffer, { desc = "[Git] Stage buffer" })
        map("n", "<leader>ggR", gitsigns.reset_buffer, { desc = "[Git] Reset buffer" })

        map("n", "<leader>ggp", gitsigns.preview_hunk, { desc = "[Git] Preview hunk" })
        map("n", "<leader>ggP", gitsigns.preview_hunk_inline, { desc = "[Git] Preview hunk inline" })

        -- map("n", "<leader>ggb", function() gitsigns.blame_line({ full = true }) end, { desc = "[Git] Blame line" })

        -- stylua: ignore
        map("n", "<leader>ggd", gitsigns.diffthis, { desc = "[Git] diff" })
        -- stylua: ignore
        map("n", "<leader>ggD", function() gitsigns.diffthis("~") end, { desc = "[Git] diff (ALL)" })

        -- stylua: ignore
        map("n", "<leader>ggQ", function() gitsigns.setqflist("all") end, { desc = "[Git] Show diffs (ALL) in qflist" })
        -- stylua: ignore
        map("n", "<leader>ggq", gitsigns.setqflist, { desc = "[Git] Show diffs in qflist" })

        -- Text object
        map({ "o", "x" }, "ih", gitsigns.select_hunk, { desc = "[Git] Current hunk" })

        -- Toggles
        require("snacks")
          .toggle({
            name = "line blame",
            get = function()
              return require("gitsigns.config").config.current_line_blame
            end,
            set = function(enabled)
              require("gitsigns").toggle_current_line_blame(enabled)
            end,
          })
          :map("<leader>tgb")
        require("snacks")
          .toggle({
            name = "word diff",
            get = function()
              return require("gitsigns.config").config.word_diff
            end,
            set = function(enabled)
              require("gitsigns").toggle_word_diff(enabled)
            end,
          })
          :map("<leader>tgw")
      end,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
      -- require("scrollbar.handlers.gitsigns").setup()
    end,
  },

  {
    -- Conflicted with vscode_nvim, don't know why
    "kevinhwang91/nvim-hlslens",
    -- stylua: ignore
    keys = {
      { "n",  "nzz<Cmd>lua require('hlslens').start()<CR>", mode = "n", desc = "Next match",      noremap = true, silent = true },
      { "N",  "Nzz<Cmd>lua require('hlslens').start()<CR>", mode = "n", desc = "Previous match",  noremap = true, silent = true },
      { "*",  "*<Cmd>lua require('hlslens').start()<CR>",   mode = "n", desc = "Next match",      noremap = true, silent = true },
      { "#",  "#<Cmd>lua require('hlslens').start()<CR>",   mode = "n", desc = "Previous match",  noremap = true, silent = true },
      { "g*", "g*<Cmd>lua require('hlslens').start()<CR>",  mode = "n", desc = "Next match",      noremap = true, silent = true },
      { "g#", "g#<Cmd>lua require('hlslens').start()<CR>",  mode = "n", desc = "Previous match",  noremap = true, silent = true },
      { "//", "<Cmd>noh<CR>",                               mode = "n", desc = "Clear highlight", noremap = true, silent = true },

      { "/" },
      { "?" },
    },
    opts = {
      nearest_only = true,
    },
    config = function(_, opts)
      -- require('hlslens').setup() is not required
      require("scrollbar.handlers.search").setup(opts)
      -- Set vim highlight group for HlSearchLens
      -- vim.cmd([[highlight link HlSearchLens CurSearch]])
      vim.api.nvim_set_hl(0, "HlSearchLens", { link = "CurSearch" })
      vim.api.nvim_set_hl(0, "HlSearchLensNear", { fg = "#CBA6F7" })
    end,
  },

  {
    "petertriho/nvim-scrollbar",
    event = "BufReadPost",
    opts = {
      handle = {
        text = " ",
        blend = 60, -- Integer between 0 and 100. 0 for fully opaque and 100 to full transparent. Defaults to 30.
        color = nil,
        color_nr = nil, -- cterm
        highlight = "Visual",
        hide_if_all_visible = true, -- Hides handle if all lines are visible
      },
      handelers = {
        gitsigns = true, -- for gitsigns
        search = true, -- for hlslens
      },
      marks = {
        Search = {
          color = "#CBA6F7",
        },
        GitAdd = { text = "┃" },
        GitChange = { text = "┃" },
        GitDelete = { text = "_" },
      },
    },
    config = function(_, opts)
      require("scrollbar").setup(opts)
    end,
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    keys = {
      -- stylua: ignore
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "[Which-key] Buffer Local Keymaps", },
    },

    opts = {
      ---@type false | "classic" | "modern" | "helix"
      preset = "helix",
      win = {
        -- no_overlap = true,
        title = false,
        width = 0.5,
      },
      -- stylua: ignore
      spec = {
        { "<leader>tg", group = "[Git] Toggle"                },
        { "<leader>gg", group = "[Git]"                       },
        { "<leader>cc", group = "[CodeCompanion]", icon = "" },
        { "<leader>D",  group = "[Dap]",           icon = "" },
        { "<leader>w",  group = "[Workspace]"                 },
        { "<leader>s",  group = "[Snacks]"                    },
        { "<leader>t",  group = "[Snacks] Toggle"             },
        { "<leader>g",  group = "[Trouble] / [Git]"           },
      },
      -- expand all nodes wighout a description
      expand = function(node)
        return not node.desc
      end,
    },
    opts_extend = { "spec" },
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "AndreM222/copilot-lualine",
    },
    event = "BufWinEnter",
    opts = {
      options = {
        theme = "catppuccin",
        always_divide_middle = false,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = {},
        lualine_y = { "encoding", "fileformat", "filetype", "progress" },
        lualine_z = { "location" },
      },
      -- stylua: ignore
      winbar = {
        lualine_a = { "filename", },
        lualine_b = { { function() return " " end, color = "Comment", }, },
        lualine_x = { "lsp_status", },
      },
      inactive_winbar = {
        -- Always show winbar
        -- stylua: ignore
        lualine_b = { function() return " " end, },
      },
    },
    config = function(_, opts)
      local mocha = require("catppuccin.palettes").get_palette("mocha")

      local function show_macro_recording()
        local recording_register = vim.fn.reg_recording()
        if recording_register == "" then
          return ""
        else
          return "󰑋 " .. recording_register
        end
      end

      local macro_recording = {
        show_macro_recording,
        color = { fg = "#333333", bg = mocha.red },
        separator = { left = "", right = "" },
        padding = 0,
      }

      local copilot = {
        "copilot",
        show_colors = true,
        symbols = {
          status = {
            hl = {
              enabled = mocha.green,
              sleep = mocha.overlay0,
              disabled = mocha.surface0,
              warning = mocha.peach,
              unknown = mocha.red,
            },
          },
          spinner_color = mocha.mauve,
        },
      }

      table.insert(opts.sections.lualine_x, 1, macro_recording)
      table.insert(opts.sections.lualine_c, copilot)

      require("lualine").setup(opts)
    end,
  },

  -- New replacement of tabline
  {
    "romgrk/barbar.nvim",
    version = "^1.0.0", -- optional: only update when a new 1.x version is released
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    opts = {
      animation = false,
      -- Automatically hide the tabline when there are this many buffers left.
      -- Set to any value >=0 to enable.
      auto_hide = 1,
      -- Set the filetypes which barbar will offset itself for
      sidebar_filetypes = {
        -- Default values: {event = 'BufWinLeave', text = '', align = 'left'}
        NvimTree = {
          text = "NvimTree",
          event = "BufWinLeave",
        },
        undotree = {
          text = "UndoTree",
        },
      },
    },
    lazy = false,
    -- event = { "VeryLazy" },
    -- stylua: ignore
    keys = {
      { "<A-<>", "<CMD>BufferMovePrevious<CR>", mode = {"n"}, desc = "[Buffer] Move buffer left"  },
      { "<A->>", "<CMD>BufferMoveNext<CR>",     mode = {"n"}, desc = "[Buffer] Move buffer right" },
      { "<A-1>", "<CMD>BufferGoto 1<CR>",       mode = {"n"}, desc = "[Buffer] Go to buffer 1"    },
      { "<A-2>", "<CMD>BufferGoto 2<CR>",       mode = {"n"}, desc = "[Buffer] Go to buffer 2"    },
      { "<A-3>", "<CMD>BufferGoto 3<CR>",       mode = {"n"}, desc = "[Buffer] Go to buffer 3"    },
      { "<A-4>", "<CMD>BufferGoto 4<CR>",       mode = {"n"}, desc = "[Buffer] Go to buffer 4"    },
      { "<A-5>", "<CMD>BufferGoto 5<CR>",       mode = {"n"}, desc = "[Buffer] Go to buffer 5"    },
      { "<A-6>", "<CMD>BufferGoto 6<CR>",       mode = {"n"}, desc = "[Buffer] Go to buffer 6"    },
      { "<A-7>", "<CMD>BufferGoto 7<CR>",       mode = {"n"}, desc = "[Buffer] Go to buffer 7"    },
      { "<A-8>", "<CMD>BufferGoto 8<CR>",       mode = {"n"}, desc = "[Buffer] Go to buffer 8"    },
      { "<A-9>", "<CMD>BufferGoto 9<CR>",       mode = {"n"}, desc = "[Buffer] Go to buffer 9"    },
      { "<A-h>", "<CMD>BufferPrevious<CR>",     mode = {"n"}, desc = "[Buffer] Previous buffer"   },
      { "<A-l>", "<CMD>BufferNext<CR>",         mode = {"n"}, desc = "[Buffer] Next buffer"       },
      { "[b",    "<CMD>BufferPrevious<CR>",     mode = {"n"}, desc = "[Buffer] Previous buffer"   },
      { "]b",    "<CMD>BufferNext<CR>",         mode = {"n"}, desc = "[Buffer] Next buffer"       },
      { "<A-w>", "<CMD>BufferClose<CR>",        mode = {"n"}, desc = "Close buffer"               },
      { "<A-u>", "<CMD>BufferRestore<CR>",      mode = {"n"}, desc = "Restore buffer"             },
    },
  },

  {
    "kosayoda/nvim-lightbulb",
    event = "LspAttach",
    opts = {
      autocmd = { enabled = true },
      sign = {
        enabled = false,
        text = "",
      },
      virtual_text = {
        enabled = true,
        text = "",
      },
    },
  },

  -- {
  --   "aznhe21/actions-preview.nvim",
  --   -- stylua: ignore
  --   keys = {
  --     { "<leader>a",   function() require("actions-preview").code_actions() end, desc = "[LSP] Code action", noremap = true, silent = true, },
  --     { "<A-a>",   function() require("actions-preview").code_actions() end, desc = "[LSP] Code action", mode = "i", noremap = true, silent = true, },
  --     { "<leader>gra", function() require("actions-preview").code_actions() end, desc = "[LSP] Code action", noremap = true, silent = true, },
  --   },
  --   opts = function()
  --     local hl = require("actions-preview.highlight")
  --     return {
  --       backend = { "snacks", "telescope" },
  --
  --       snacks = {
  --         layout = {
  --           reverse = false,
  --           layout = {
  --             backdrop = false,
  --             width = 0.5,
  --             min_width = 80,
  --             height = 0.4,
  --             min_height = 3,
  --             box = "vertical",
  --             border = "rounded",
  --             title = "{title}",
  --             title_pos = "center",
  --             { win = "input", height = 1, border = "bottom" },
  --             { win = "list", height = 5, border = "none" },
  --             { win = "preview", title = "{preview}", height = 0.4, border = "top" },
  --           },
  --         },
  --       },
  --       -- priority list of external command to highlight diff
  --       -- disabled by default, must be set by yourself
  --       highlight_command = {
  --         -- Highlight diff using delta: https://github.com/dandavison/delta
  --         -- The argument is optional, in which case "delta" is assumed to be
  --         -- specified.
  --         hl.delta("delta --config " .. os.getenv("HOME") .. "/.config/nvim/configs/.gitconfig"),
  --       },
  --     }
  --   end,
  -- },

  {
    "rachartier/tiny-code-action.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      {
        "folke/snacks.nvim",
        opts = {
          -- terminal = {},
        },
      },
    },
    event = "LspAttach",
    -- stylua: ignore
    keys = {
      { "<leader>a",   function() require("tiny-code-action").code_action({}) end, desc = "[LSP] Code action", noremap = true, silent = true, },
      { "<A-a>",   function() require("tiny-code-action").code_action({}) end, desc = "[LSP] Code action", mode = "i", noremap = true, silent = true, },
      -- { "<leader>gra", function() require("tiny-code-action").code_action({}) end, desc = "[LSP] Code action", noremap = true, silent = true, },
    },
    opts = {
      -- backend = "delta",
      backend_opts = {
        delta = {
          -- The arguments to pass to delta
          -- If you have a custom configuration file, you can set the path to it like so:
          -- args = {
          --   "--config " .. os.getenv("HOME") .. "/.config/nvim/configs/.gitconfig",
          -- },
        },
      },
      picker = {
        "snacks",
        opts = {
          layout = {
            reverse = false,
            layout = {
              backdrop = false,
              width = 0.5,
              min_width = 80,
              height = 0.8,
              min_height = 3,
              box = "vertical",
              border = "rounded",
              title = "{title}",
              title_pos = "center",
              { win = "input", height = 1, border = "bottom" },
              { win = "list", height = 5, border = "none" },
              -- { win = "preview", title = "{preview}", height = 0.4, border = "top" },
              { win = "preview", title = "{preview}", border = "top" },
            },
          },
        },
      },
    },
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>sN", "<CMD>Noice pick<CR>", desc = "[Noice] Pick history messages" },
      { "<leader>N", "<CMD>Noice<CR>", desc = "[Noice] Show history messages" },
    },
    opts = {
      routes = {
        {
          filter = {
            event = "msg_show",
            kind = "search_count",
          },
          opts = { skip = true },
        },
        {
          filter = {
            event = "msg_show",
            kind = "",
          },
          opts = { skip = true },
        },
      },
      lsp = {
        progress = {
          enabled = false, -- lsp progress is handled by fidget.nvim
        },
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
          ["vim.lsp.util.stylize_markdown"] = false,
          -- ["cmp.entry.get_documentation"] = true,
        },
        message = {
          -- Messages shown by lsp servers
          enabled = true,
          view = "notify",
          opts = {},
        },
      },
      notify = {
        enabled = false,
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = false, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
    },
  },

  {
    "nvzone/showkeys",
    cmd = "ShowkeysToggle",
    opts = {
      maxkeys = 5,
    },
  },

  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    opts = {
      provider_selector = function(_, _, _)
        return { "treesitter", "indent" }
      end,

      open_fold_hl_timeout = 0,
      fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = (" 󰁂 %d "):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
      end,
    },

    init = function()
      vim.o.foldenable = true
      vim.o.foldcolumn = "0" -- '0' is not bad
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.opt.fillchars = {
        fold = " ",
        foldopen = "▾",
        foldsep = "│",
        foldclose = "▸",
      }
    end,

    config = function(_, opts)
      require("ufo").setup(opts)
      -- Ensure our ufo foldlevel is set for the buffer
      vim.api.nvim_create_autocmd("BufReadPre", {
        callback = function()
          vim.b.ufo_foldlevel = 0
        end,
      })

      ---@param num integer Set the fold level to this number
      local set_buf_foldlevel = function(num)
        vim.b.ufo_foldlevel = num
        require("ufo").closeFoldsWith(num)
      end

      ---@param num integer The amount to change the UFO fold level by
      local change_buf_foldlevel_by = function(num)
        local foldlevel = vim.b.ufo_foldlevel or 0
        -- Ensure the foldlevel can't be set negatively
        if foldlevel + num >= 0 then
          foldlevel = foldlevel + num
        else
          foldlevel = 0
        end
        set_buf_foldlevel(foldlevel)
      end

      -- Keymaps
      vim.keymap.set("n", "K", function()
        local winid = require("ufo").peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end)
      vim.keymap.set("n", "gk", function()
        local winid = require("ufo").peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end)

      -- stylua: ignore
      vim.keymap.set("n", "zM", function() set_buf_foldlevel(0) end, { desc = "[UFO] Close all folds" })
      vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "[UFO] Open all folds" })

      vim.keymap.set("n", "zm", function()
        local count = vim.v.count
        if count == 0 then
          count = 1
        end
        change_buf_foldlevel_by(-count)
      end, { desc = "[UFO] Fold More" })
      vim.keymap.set("n", "zr", function()
        local count = vim.v.count
        if count == 0 then
          count = 1
        end
        change_buf_foldlevel_by(count)
      end, { desc = "[UFO] Fold Less" })

      -- 99% sure `zS` isn't mapped by default
      vim.keymap.set("n", "zS", function()
        if vim.v.count == 0 then
          vim.notify("No foldlevel given to set!", vim.log.levels.WARN)
        else
          set_buf_foldlevel(vim.v.count)
        end
      end, { desc = "[UFO] Set foldlevel" })

      -- Delete some predefined keymaps as they are not compatible with nvim-ufo
      vim.keymap.set("n", "zE", "<NOP>", { desc = "Disabled" })
      vim.keymap.set("n", "zx", "<NOP>", { desc = "Disabled" })
      vim.keymap.set("n", "zX", "<NOP>", { desc = "Disabled" })
    end,
  },

  {
    "lukas-reineke/virt-column.nvim",
    opts = {
      -- char = "|",
      -- char = "",
      -- char = "┇",
      -- char = "∶",
      -- char = "∷",
      -- char = "║",
      -- char = "⋮",
      char = "",
      -- char = "󰮾",
      virtcolumn = "+1",
    },
  },
}
