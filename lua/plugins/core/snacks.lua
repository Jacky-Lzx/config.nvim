return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      dashboard = {
        enabled = true,
        preset = {
          header = [[
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⠀⠀⠀⠀⠀⠀⠸⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀⠀⢻⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣷⠀⠀⠀⠀⠀⠀⠘⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣧⠀⠀⠀⠀⠀⠀⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣆⠀⠀⠀⠀⠀⢹⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣿⣧⡀⠀⠀⠀⢸⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡀⠀⠀⠀⢹⣿⣿⣿⣷⣄⠀⠀⣸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⢄⣄⠀⠀⠀⠀⠀⠀⠀⠀⠸⣾⣿⣄⠀⠀⠀⢻⣿⣿⡿⢿⣿⣶⣾⣿⠟⠙⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⡀⠀⠀⠀⠻⣿⡇⠀⠙⣿⣿⣿⠀⢠⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠁⠀⠀⠀⠀⠘⢿⣦⣤⣽⣿⣿⣶⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⡇⠀⠀⠀⢀⣀⣠⣤⣤⣤⣄⣰⣿⡟⠀⠀⠀⠀⠀⢀⡀⢽⠿⠿⠛⠛⠛⠂⠒⢠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣔⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠡⣈⠀⡁⠀⡁⢈⠀⡡⠚⠁⢀⠤⠠⠐⠢⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢨⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠻⣇⠀⠀⠀⠀⠀⠀⠀⡷⠀⠂⠐⠠⣺⠀⠀⠀⠀⡀⠠⠄⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⡿⠁⠀⠀⠹⣿⣿⣿⠀⠀⠀⢻⠀⠀⠀⠀⠀⠀⠀⣏⠀⡁⢈⠀⡻⠀⡀⠀⠀⠁⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣿⡀⠀⠀⢠⣿⣿⣿⣦⣀⣠⣿⠀⠀⠀⠀⠀⠀⠀⡧⠀⠄⠠⠈⠄⡀⢃⠀⠀⠀⠀⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿⣷⣾⣿⣿⣿⣿⣿⣿⡿⠃⢀⡀⠀⠀⠀⠀⢀⢱⡄⠂⠐⠀⠂⢹⡿⠦⠤⠤⠌⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⡿⠿⠿⠿⠿⠛⢫⠁⠀⡠⠃⠀⠅⠀⠀⠀⡌⣼⡇⡁⢈⠠⡙⠌⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⠃⠀⠀⠀⡒⠂⠀⠁⠀⠉⠀⠁⠀⠀⢀⠜⢤⣿⠃⠄⠠⠘⠀⠂⠘⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⡃⠸⠀⠃⣿⠟⠄⠀⠄⠣⡀⠀⠀⠀⡠⡁⡁⣾⡟⡁⠀⡁⣬⣤⢽⣬⠀⡀⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⣱⢀⠂⠀⠀⣷⣶⣔⣶⣧⠸⣉⣢⣀⡴⠁⢄⣼⡿⠐⠀⠂⣰⣿⣿⣿⣿⣀⣄⣠⣉⠦⠤⠤⠄⠀⠤⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠉⠐⠂⠦⠊⠙⣿⡿⣿⠏⠁⠃⠀⠀⠈⠑⠛⠉⠁⠚⠒⠉⠀⢻⣿⣸⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠁⢣⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
          ]],
        },
      },
      explorer = { enabled = false },
      image = {
        enabled = true,
        -- Automatically show image in a floating window when mouse hovering over it
        doc = { inline = false, float = true, max_width = 60, max_height = 30 },
        math = { latex = { font_size = "small" } },
      },
      indent = {
        enabled = true,
        animate = { enabled = false },
        indent = { only_scope = true },
        scope = {
          -- Enable highlighting the current scope
          enabled = false,
          -- underline the start of the scope
          underline = true,
        },
        -- When enabled, scopes will be rendered as chunks, except for the top-level scope which will be rendered as a scope.
        chunk = { enabled = true },
      },
      input = { enabled = true },
      lazygit = {
        enabled = true,
        configure = false,
      },
      notifier = {
        enabled = true,
        style = "notification",
      },
      picker = {
        enabled = true,
        actions = {
          system_open = {
            desc = "Open with system app",
            action = function(picker, item)
              local items = picker:selected({ fallback = true })
              local lines = vim.tbl_map(function(it)
                local path = it.file or it.text
                if path then
                  -- Snacks.util.system_open(path)
                  vim.fn.jobstart({ "open", path }, { detach = true })
                else
                  Snacks.notify("No file or text to open", { title = "Snacks Picker", level = "error" })
                end
              end, items)
            end,
          },
          copy_selected = {
            desc = "Copy selected to clipboard",
            action = function(picker)
              -- selected items; if none selected, fall back to current item
              local items = picker:selected({ fallback = true })

              -- choose what you want to copy: file path, text, etc.
              local lines = vim.tbl_map(function(it)
                return it.file or it.text
              end, items)

              local value = table.concat(lines, "\n")
              vim.fn.setreg("+", value) -- system clipboard

              Snacks.notify(("Copied %d item(s) to clipboard"):format(#lines), { title = "Snacks Picker" })
            end,
          },
        },
        previewers = {
          diff = {
            builtin = false, -- use Neovim for previewing diffs (true) or use an external tool (false)
            cmd = { "delta" }, -- example to show a diff with delta
          },
          git = {
            builtin = false, -- use Neovim for previewing git output (true) or use git (false)
            args = {}, -- additional arguments passed to the git command. Useful to set pager options using `-c ...`
          },
        },
        sources = {
          spelling = {
            layout = { reverse = false, preset = "select" },
          },
          select = {
            layout = { reverse = false, preset = "select" },
          },
        },
        win = {
          input = {
            keys = {
              ["<Tab>"] = { "select_and_prev", mode = { "i", "n" } },
              ["<S-Tab>"] = { "select_and_next", mode = { "i", "n" } },
              ["<A-Up>"] = { "history_back", mode = { "n", "i" } },
              ["<A-Down>"] = { "history_forward", mode = { "n", "i" } },
              ["<A-j>"] = { "list_down", mode = { "n", "i" } },
              ["<A-k>"] = { "list_up", mode = { "n", "i" } },
              ["<C-u>"] = { "preview_scroll_up", mode = { "n", "i" } },
              ["<C-d>"] = { "preview_scroll_down", mode = { "n", "i" } },
              ["<A-u>"] = { "list_scroll_up", mode = { "n", "i" } },
              ["<A-d>"] = { "list_scroll_down", mode = { "n", "i" } },
              ["<c-j>"] = {},
              ["<c-k>"] = {},
              ["<c-y>"] = { "copy_selected", mode = { "n", "i" } },
              ["<c-o>"] = { "system_open", mode = { "n", "i" } },
            },
          },
        },
        layout = {
          preset = "default",
        },
        layouts = {
          default = {
            reverse = true,
            layout = {
              backdrop = false,
              width = 0.8,
              min_width = 60,
              height = 0.9,
              -- min_height = 30,
              box = "vertical",
              border = true,
              title = "{title} {live} {flags}",
              title_pos = "center",
              { win = "preview", title = "{preview}", height = 0.6, border = "bottom" },
              { win = "list", border = "none" },
              { win = "input", height = 1, border = "top" },
            },
          },
        },
      },
      quickfile = { enabled = true },
      -- Create keymappings of `ii` and `ai` for textobjects, and `[i` and `]i` for jumps
      scope = {
        enabled = true,
        cursor = true,
        keys = {
          jump = {
            ["[i"] = false,
            ["]i"] = false,
          },
        },
      },
      scroll = { enabled = false },
      statuscolumn = {
        enabled = true,
        left = { "mark", "sign" }, -- priority of signs on the left (high to low)
        right = { "fold", "git" }, -- priority of signs on the right (high to low)
        folds = {
          open = true, -- show open fold icons
          git_hl = false, -- use Git Signs hl for fold icons
        },
        refresh = 50, -- refresh at most every 50ms
      },
      terminal = { enabled = true },
      words = { enabled = true },
      styles = {
        terminal = {
          relative = "editor",
          border = "rounded",
          position = "float",
          backdrop = 60,
          height = 0.9,
          width = 0.9,
          zindex = 50,
        },
        -- Keeps the image on the bottom right corner
        snacks_image = {
          relative = "editor",
          row = 0.8,
          col = -1,
        },
        -- Enable line wrapping in notification history
        notification_history = {
          wo = {
            wrap = true,
          },
        },
      },
    },

    -- stylua: ignore
    keys = {
      -- { "<A-w>", function() require("snacks").bufdelete() end, desc = "[Snacks] Delete buffer", },
      { "<leader>si", function() require("snacks").image.hover() end, desc = "[Snacks] Display image", },
      { "<A-i>", function() require("snacks").terminal() end, desc = "[Snacks] Toggle terminal", mode = { "n", "t" }, },
      -- Notification
      { "<leader>sn", function() require("snacks").picker.notifications() end, desc = "[Snacks] Notification history", },
      { "<leader>n", function() require("snacks").notifier.show_history() end, desc = "[Snacks] Notification history", },
      { "<leader>un", function() require("snacks").notifier.hide() end, desc = "[Snacks] Dismiss all notifications", },
      -- Top Pickers & Explorer
      -- { "<leader><space>", function() require("snacks").picker.smart() end, desc = "[Snacks] Smart find files", },
      { "<leader>,", function() require("snacks").picker.buffers() end, desc = "[Snacks] Buffers", },
      -- find
      { "<leader>sb", function() require("snacks").picker.buffers() end, desc = "[Snacks] Buffers", },
      { "<leader>sf", function() require("snacks").picker.files() end, desc = "[Snacks] Find files", },
      { "<leader>sp", function() require("snacks").picker.projects() end, desc = "[Snacks] Projects", },
      { "<leader>sr", function() require("snacks").picker.recent() end, desc = "[Snacks] Recent", },
      -- git
      { "<C-g>", function() require("snacks").lazygit() end, desc = "[Snacks] Lazygit", },
      { "<leader>ggl", function() require("snacks").picker.git_log() end, desc = "[Snacks] Git log", },
      { "<leader>ggd", function() require("snacks").picker.git_diff() end, desc = "[Snacks] Git diff", },
      { "<leader>ggb", function() require("snacks").git.blame_line() end, desc = "[Snacks] Git blame line", },
      { "<leader>ggB", function() require("snacks").gitbrowse() end, desc = "[Snacks] Git browse", },
      -- Grep
      -- { "<leader>sb", function() require("snacks").picker.lines() end, desc = "[Snacks] Buffer lines" },
      -- { "<leader>sB", function() require("snacks").picker.grep_buffers() end, desc = "[Snacks] Grep open buffers" },
      { "<leader>sg", function() require("snacks").picker.grep() end, desc = "[Snacks] Grep", },
      -- { "<leader>sw", function() require("snacks").picker.grep_word() end, desc = "[Snacks] Visual selection or word", mode = { "n", "x" } },
      -- search
      { '<leader>s"', function() require("snacks").picker.registers() end, desc = "[Snacks] Registers", },
      { "<leader>s/", function() require("snacks").picker.search_history() end, desc = "[Snacks] Search history", },
      { "<leader>sa", function() require("snacks").picker.spelling() end, desc = "[Snacks] Spelling", },
      { "<leader>sA", function() require("snacks").picker.autocmds() end, desc = "[Snacks] Autocmds", },
      { "<leader>s:", function() require("snacks").picker.command_history() end, desc = "[Snacks] Command history", },
      { "<leader>sc", function() require("snacks").picker.commands() end, desc = "[Snacks] Commands", },
      { "<leader>sd", function() require("snacks").picker.diagnostics() end, desc = "[Snacks] Diagnostics", },
      { "<leader>sD", function() require("snacks").picker.diagnostics_buffer() end, desc = "[Snacks] Diagnostics buffer", },
      { "<leader>sH", function() require("snacks").picker.help() end, desc = "[Snacks] Help pages", },
      { "<leader>sh", function() require("snacks").picker.highlights() end, desc = "[Snacks] Highlights", },
      { "<leader>sI", function() require("snacks").picker.icons() end, desc = "[Snacks] Icons", },
      { "<leader>sj", function() require("snacks").picker.jumps() end, desc = "[Snacks] Jumps", },
      { "<leader>sk", function() require("snacks").picker.keymaps() end, desc = "[Snacks] Keymaps", },
      { "<leader>sl", function() require("snacks").picker.loclist() end, desc = "[Snacks] Location list", },
      { "<leader>sm", function() require("snacks").picker.marks() end, desc = "[Snacks] Marks", },
      { "<leader>sM", function() require("snacks").picker.man() end, desc = "[Snacks] Man pages", },
      { "<leader>sp", function() require("snacks").picker.lazy() end, desc = "[Snacks] Search for plugin spec", },
      { "<leader>sq", function() require("snacks").picker.qflist() end, desc = "[Snacks] Quickfix list", },
      { "<leader>sr", function() require("snacks").picker.resume() end, desc = "[Snacks] Resume", },
      { "<leader>su", function() require("snacks").picker.undo() end, desc = "[Snacks] Undo history", },
      -- LSP
      { "gd", function() require("snacks").picker.lsp_definitions() end, desc = "[Snacks] Goto definition", },
      { "gD", function() require("snacks").picker.lsp_declarations() end, desc = "[Snacks] Goto declaration", },
      { "gi", function() require("snacks").picker.lsp_references() end, {desc = "[Snacks] References"}, },
      { "gI", function() require("snacks").picker.lsp_implementations() end, desc = "[Snacks] Goto implementation", },
      { "gy", function() require("snacks").picker.lsp_type_definitions() end, desc = "[Snacks] Goto t[y]pe definition", },
      { "gci", function() Snacks.picker.lsp_incoming_calls() end, desc = "[Snacks] Calls Incoming" },
      { "gco", function() Snacks.picker.lsp_outgoing_calls() end, desc = "[Snacks] Calls Outgoing" },
      { "<leader>ss", function() require("snacks").picker.lsp_symbols() end, desc = "[Snacks] LSP symbols", },
      { "<leader>sS", function() require("snacks").picker.lsp_workspace_symbols() end, desc = "[Snacks] LSP workspace symbols", },
      -- Words
      { "]]", function() require("snacks").words.jump(vim.v.count1) end, desc = "[Snacks] Next Reference", mode = { "n", "t" }, },
      { "[[", function() require("snacks").words.jump(-vim.v.count1) end, desc = "[Snacks] Prev Reference", mode = { "n", "t" }, },
      -- Zen mode
      { "<leader>Z", function() require("snacks").zen() end, desc = "[Snacks] Toggle Zen Mode", },
      { "<leader>z", function() require("snacks").zen.zoom() end, desc = "[Snacks] Toggle Zoom", },
    },

    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          Snacks.toggle
            .new({
              id = "Animation",
              name = "Animation",
              get = function()
                return Snacks.animate.enabled()
              end,
              set = function(state)
                vim.g.snacks_animate = state
              end,
            })
            :map("<leader>ta")

          Snacks.toggle
            .new({
              id = "scroll_anima",
              name = "Scroll animation",
              get = function()
                return Snacks.scroll.enabled
              end,
              set = function(state)
                if state then
                  Snacks.scroll.enable()
                else
                  Snacks.scroll.disable()
                end
              end,
            })
            :map("<leader>tS")

          -- Create some toggle mappings
          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>ts")
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>tw")
          Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>tL")
          Snacks.toggle.line_number():map("<leader>tl")
          Snacks.toggle
            .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
            :map("<leader>tc")
          Snacks.toggle.treesitter():map("<leader>tT")
          Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>tb")
          Snacks.toggle.inlay_hints():map("<leader>th")
          Snacks.toggle.indent():map("<leader>tG")
          Snacks.toggle.dim():map("<leader>tD")
          -- Toggle the profiler
          Snacks.toggle.profiler():map("<leader>tPp")
          -- Toggle the profiler highlights
          Snacks.toggle.profiler_highlights():map("<leader>tPh")
          require("which-key").add({
            { "<leader>tP", group = "[profiler]" },
          })

          vim.keymap.del("n", "grn")
          vim.keymap.del("n", "gra")
          vim.keymap.del("n", "grr")
          vim.keymap.del("n", "gri")

          vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { bg = "#2A2B3D" })
          vim.api.nvim_set_hl(0, "SnacksPickerPreviewCursorLine", { bg = "#2A2B3D" })
          vim.api.nvim_set_hl(0, "SnacksPickerSearch", { link = "SelectionInactive" })
          vim.api.nvim_set_hl(0, "SnacksPickerMatch", { link = "SelectionInactive" })
        end,
      })
    end,
  },
}
