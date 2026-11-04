local platform = require("utils.platform")

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = false }, -- ui-tools owns the start screen.
      toggle = { which_key = false },
      explorer = { enabled = false },
      image = {
        enabled = false,
        -- Automatically show image in a floating window when mouse hovering over it
        doc = { inline = false, float = false, max_width = 60, max_height = 30 },
        math = { latex = { font_size = "small" } },
      },
      indent = { enabled = false }, -- ui-tools owns indentation guides and chunks.
      input = { enabled = false }, -- Native vim.ui.input is displayed by input-tools.
      lazygit = { enabled = false }, -- git-tools owns the Lazygit terminal.
      notifier = {
        enabled = false, -- notification-tools owns vim.notify.
        style = "notification",
      },
      picker = {
        enabled = true,
        ui_select = false, -- Generic selection is owned by selection-tools.nvim.
        actions = {
          system_open = {
            desc = "Open with system app",
            action = function(picker, item)
              local items = picker:selected({ fallback = true })
              for _, it in ipairs(items) do
                local path = it.file or it.text
                if path then
                  local ok, err = platform.open(path)
                  if not ok then
                    Snacks.notify(err, { title = "Snacks Picker", level = "error" })
                  end
                else
                  Snacks.notify("No file or text to open", { title = "Snacks Picker", level = "error" })
                end
              end
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
      statuscolumn = { enabled = false }, -- ui-tools owns the gutter.
      zen = { enabled = false },
      dim = { enabled = false },
      terminal = { enabled = false }, -- task-tools owns interactive terminals.
      words = { enabled = false }, -- Reference highlighting/navigation is owned by lsp-tools.nvim.
      styles = {
        -- Enable line wrapping in notification history
        notification_history = {
          wo = {
            wrap = true,
          },
          relative = "editor",
          border = "rounded",
          position = "float",
          backdrop = 60,
          height = 0.8,
          width = 0.8,
          zindex = 50,
        },
      },
    },

    -- stylua: ignore
    keys = {
      -- { "<A-w>", function() require("snacks").bufdelete() end, desc = "[Snacks] Delete buffer", },
      -- Top Pickers & Explorer
      -- { "<leader><space>", function() require("snacks").picker.smart() end, desc = "[Snacks] Smart find files", },
      -- find
      -- git
      -- Grep
      -- { "<leader>sb", function() require("snacks").picker.lines() end, desc = "[Snacks] Buffer lines" },
      -- { "<leader>sB", function() require("snacks").picker.grep_buffers() end, desc = "[Snacks] Grep open buffers" },
      -- { "<leader>sw", function() require("snacks").picker.grep_word() end, desc = "[Snacks] Visual selection or word", mode = { "n", "x" } },
      -- search
      { "<leader>sp", function() require("snacks").picker.lazy() end, desc = "[Snacks] Search for plugin spec", },
      -- LSP
      { "gci", function() require("lsp-tools").call_hierarchy({ direction = "incoming" }) end, desc = "[LSP] Incoming call tree" },
      { "gco", function() require("lsp-tools").call_hierarchy({ direction = "outgoing" }) end, desc = "[LSP] Outgoing call tree" },
    },

    init = function()
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("lzx_snacks_very_lazy", { clear = true }),
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

          require("integrations.snacks_toggles").setup(Snacks)
        end,
      })
    end,
  },
}
