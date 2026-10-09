return {
  {
    "saghen/blink.cmp",
    dependencies = { "Jacky-Lzx/pairs.nvim" },

    event = { "InsertEnter", "CmdlineEnter" },

    -- use a release tag to download pre-built binaries
    version = "*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',
    opts_extend = { "sources.default" },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      -- 'super-tab' for mappings similar to vscode (tab to accept)
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-n/C-p or Up/Down: Select next/previous item
      -- C-e: Hide menu
      -- C-k: Toggle signature help (if signature.enabled = true)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      keymap = {
        -- If the command/function returns false or nil, the next command/function will be run.
        preset = "default",
        -- stylua: ignore start
        ["<A-k>"] = { function(cmp) return cmp.select_prev({ auto_insert = false }) end, "fallback", },
        ["<A-j>"] = { function(cmp) return cmp.select_next({ auto_insert = false }) end, "fallback", },
        ["<C-p>"] = { function(cmp) return cmp.select_prev({ auto_insert = false }) end, "fallback", },
        ["<C-n>"] = { function(cmp) return cmp.select_next({ auto_insert = false }) end, "fallback", },

        ["<A-u>"] = { function(cmp) return cmp.select_prev({ count = 5 }) end, "fallback", },
        ["<A-d>"] = { function(cmp) return cmp.select_next({ count = 5 }) end, "fallback", },

        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },

        ["<Tab>"] = { function(cmp) return cmp.accept() end, "fallback", },
        ["<CR>"] = { function(cmp) return cmp.accept() end, function() return require("integrations.blink_pairs").newline() end, "fallback", },
        -- Close current completion and insert a newline
        ["<S-CR>"] = { function(cmp) cmp.hide() return false end, "fallback", },

        -- Show/Remove completion
        ["<A-/>"] = { function(cmp) if cmp.is_menu_visible() then return cmp.hide() else return cmp.show() end end, "fallback", },
        -- stylua: ignore end

        ["<A-n>"] = {
          function(cmp)
            return require("integrations.blink_completion").cycle(cmp, 1)
          end,
        },
        ["<A-p>"] = {
          function(cmp)
            return require("integrations.blink_completion").cycle(cmp, -1)
          end,
        },
      },

      appearance = {
        -- sets the fallback highlight groups to nvim-cmp's highlight groups
        -- useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release, assuming themes add support
        -- use_nvim_cmp_as_default = true,
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        -- nerd_font_variant = "mono",
        nerd_font_variant = "normal",
      },

      sources = {
        -- Default list of enabled providers defined so that you can extend it
        -- elsewhere in your config, without redefining it, due to `opts_extend`
        -- "buffer" source is used to complete words
        default = { "lsp", "path", "buffer" },
        -- default = { "lazydev", "copilot", "lsp", "path", "snippets" },

        -- default = function()
        --   local success, node = pcall(vim.treesitter.get_node)
        --   if success and node and vim.tbl_contains({ "comment", "line_comment", "block_comment" }, node:type()) then
        --     return { "dictionary", "buffer" }
        --   else
        --     return { "dictionary", "lazydev", "copilot", "lsp", "path", "snippets", "buffer" }
        --   end
        -- end,

        providers = {
          path = {
            score_offset = 95,
            opts = {
              get_cwd = function(_)
                return vim.fn.getcwd()
              end,
            },
          },
          buffer = {
            score_offset = 20,

            -- Include hidden buffers only when they share the current filetype.
            opts = {
              get_bufnrs = function()
                local current = vim.api.nvim_get_current_buf()
                return vim.tbl_filter(function(bufnr)
                  return vim.api.nvim_buf_is_loaded(bufnr)
                    and vim.bo[bufnr].buftype == ""
                    and (bufnr == current or (vim.bo[current].filetype ~= "" and vim.bo[bufnr].filetype == vim.bo[current].filetype))
                    and vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr)) <= 1024 * 1024
                end, vim.api.nvim_list_bufs())
              end,
            },
          },
          lsp = {
            -- Default
            -- Filter text items from the LSP provider, since we have the buffer provider for that
            transform_items = function(_, items)
              return vim.tbl_filter(function(item)
                return (item.kind ~= require("blink.cmp.types").CompletionItemKind.Text)
                  -- Disable snippet completions from LSP
                  and (item.kind ~= require("blink.cmp.types").CompletionItemKind.Snippet)
              end, items)
            end,
            score_offset = 60,
            fallbacks = { "buffer" },
          },
          cmdline = {
            -- Ignores cmdline completions when executing shell commands
            enabled = function()
              return vim.fn.getcmdtype() ~= ":" or not vim.fn.getcmdline():match("^[%%0-9,'<>%-]*!")
            end,
          },
        },
      },

      fuzzy = {
        implementation = "prefer_rust_with_warning",
        sorts = {
          -- "exact",
          "score",
          "kind",
          "label",
          "sort_text",
        },
      },

      completion = {
        -- NOTE: some LSPs may add auto brackets themselves anyway
        accept = { auto_brackets = { enabled = true } },
        list = { selection = { preselect = true, auto_insert = false } },

        menu = {
          border = "rounded",
          max_height = 20,

          -- When ghost text is enabled (completion.ghost_text.enabled = true), you may want the menu to avoid
          -- overlapping with the ghost text. You may provide a custom completion.menu.direction_priority function to
          -- achieve this
          -- See https://cmp.saghen.dev/recipes#avoid-multi-line-completion-ghost-text
          direction_priority = function()
            local ctx = require("blink.cmp").get_context()
            local item = require("blink.cmp").get_selected_item()
            if ctx == nil or item == nil then
              return { "s", "n" }
            end

            local item_text = item.textEdit ~= nil and item.textEdit.newText or item.insertText or item.label
            local is_multi_line = item_text:find("\n") ~= nil

            -- after showing the menu upwards, we want to maintain that direction
            -- until we re-open the menu, so store the context id in a global variable
            if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
              vim.g.blink_cmp_upwards_ctx_id = ctx.id
              return { "n", "s" }
            end
            return { "s", "n" }
          end,
        },
        documentation = {
          auto_show = true,
          -- Delay before showing the documentation window
          auto_show_delay_ms = 200,
          window = {
            min_width = 10,
            max_width = 120,
            max_height = 20,
            border = "rounded",
            winblend = 0,
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
            -- Note that the gutter will be disabled when border ~= 'none'
            scrollbar = true,
            -- Which directions to show the documentation window,
            -- for each of the possible menu window directions,
            -- falling back to the next direction when there's not enough space
            direction_priority = {
              menu_north = { "e", "w", "n", "s" },
              menu_south = { "e", "w", "s", "n" },
            },
          },
        },
        -- Displays a preview of the selected item on the current line
        ghost_text = {
          enabled = true,
          -- Show the ghost text when an item has been selected
          show_with_selection = true,
          -- Show the ghost text when no item has been selected, defaulting to the first item
          show_without_selection = false,
          -- Show the ghost text when the menu is open
          show_with_menu = true,
          -- Show the ghost text when the menu is closed
          show_without_menu = true,
        },
      },
      signature = {
        enabled = false,
        window = {
          min_width = 1,
          max_width = 100,
          max_height = 10,
          border = "single", -- Defaults to `vim.o.winborder` on nvim 0.11+ or 'padded' when not defined/<=0.10
          winblend = 0,
          winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder",
          scrollbar = false, -- Note that the gutter will be disabled when border ~= 'none'
          -- Which directions to show the window,
          -- falling back to the next direction when there's not enough space,
          -- or another window is in the way
          direction_priority = { "n" },
          -- Disable if you run into performance issues
          treesitter_highlighting = true,
          show_documentation = true,
        },
      },
      -- Completion in the command line behaves differently
      -- The <Enter> input will not select the selected item
      -- The <Tab> input will select the selected item
      cmdline = {
        completion = {
          menu = {
            auto_show = true,
          },
          list = {
            selection = {
              preselect = true,
              auto_insert = false,
            },
          },
        },
        -- stylua: ignore
        keymap = {
          preset = "none",
          ["<Up>"] = { function(cmp) return cmp.select_prev({ auto_insert = false }) end, "fallback", },
          ["<Down>"] = { function(cmp) return cmp.select_next({ auto_insert = false }) end, "fallback", },
          ["<A-k>"] = { function(cmp) return cmp.select_prev({ auto_insert = false }) end, "fallback", },
          ["<A-j>"] = { function(cmp) return cmp.select_next({ auto_insert = false }) end, "fallback", },
          ["<C-p>"] = { function(cmp) return cmp.select_prev({ auto_insert = false }) end, "fallback", },
          ["<C-n>"] = { function(cmp) return cmp.select_next({ auto_insert = false }) end, "fallback", },
          ["<A-u>"] = { function(cmp) return cmp.select_prev({ count = 5 }) end, "fallback", },
          ["<A-d>"] = { function(cmp) return cmp.select_next({ count = 5 }) end, "fallback", },
          ["<Tab>"] = { function(cmp) return cmp.accept() end, "fallback", },
          ["<CR>"] = { "fallback", },
          ["<A-/>"] = { function(cmp) if cmp.is_menu_visible() then return cmp.hide() else return cmp.show() end end, "fallback", },
        },
      },
    },
  },
}
