return {
  {
    "saghen/blink.cmp",

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
      -- stylua: ignore
      keymap = {
        -- If the command/function returns false or nil, the next command/function will be run.
        preset = "default",
        ["<A-k>"] = { function(cmp) return cmp.select_prev({ auto_insert = false }) end, "fallback", },
        ["<A-j>"] = { function(cmp) return cmp.select_next({ auto_insert = false }) end, "fallback", },
        ["<C-p>"] = { function(cmp) return cmp.select_prev({ auto_insert = false }) end, "fallback", },
        ["<C-n>"] = { function(cmp) return cmp.select_next({ auto_insert = false }) end, "fallback", },

        ["<A-u>"] = { function(cmp) return cmp.select_prev({ count = 5 }) end, "fallback", },
        ["<A-d>"] = { function(cmp) return cmp.select_next({ count = 5 }) end, "fallback", },

        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },

        ["<Tab>"] = { function(cmp) return cmp.accept() end, "fallback", },
        ["<CR>"] = { function(cmp) return cmp.accept() end, "fallback", },
        -- Close current completion and insert a newline
        ["<S-CR>"] = { function(cmp) cmp.hide() return false end, "fallback", },

        -- Show/Remove completion
        ["<A-/>"] = { function(cmp) if cmp.is_menu_visible() then return cmp.hide() else return cmp.show() end end, "fallback", },

        -- show with a list of providers
        ["<C-space>"] = {
          --- Disable copilot suggestions
          function(cmp)
            cmp.show({
              providers = (function()
                local success, node = pcall(vim.treesitter.get_node)
                if success and node and vim.tbl_contains({ "comment", "line_comment", "block_comment" }, node:type())
                then return { "buffer" } else return { "lazydev", "lsp", "path", "snippets" } end
              end)(),
            })
          end,
        },

        ["<A-n>"] = {
          function(cmp)
            local provider_arrs = {
              { "buffer" },
              { "snippets" },
              { "lazydev", "lsp", "path" }
            }
            local provider_index = vim.b.blink_cmp_provider_index
            if not provider_index then
              provider_index = 0
            end

            provider_index = provider_index + 1
            if provider_index > #provider_arrs then
              provider_index = 1
            end

            cmp.show({ providers = provider_arrs[provider_index] })
            vim.b.blink_cmp_provider_index = provider_index
          end,
        },
        ["<A-p>"] = {
          function(cmp)
            local provider_arrs = {
              { "buffer" },
              { "snippets" },
              { "lazydev", "lsp", "path" }
            }
            local provider_index = vim.b.blink_cmp_provider_index
            if not provider_index then
              provider_index = #provider_arrs + 1
            end

            provider_index = provider_index - 1
            if provider_index == 0 then
              provider_index = #provider_arrs
            end

            cmp.show({ providers = provider_arrs[provider_index] })
            vim.b.blink_cmp_provider_index = provider_index
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
        default = { "lazydev", "lsp", "path", "buffer" },
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

            -- The default behavior is to only show completions from visible "normal" buffers (i.e. it wouldn't include
            -- neo-tree). This will instead show completions from all buffers, even if they're not visible on screen.
            -- Note that the performance impact of this has not been tested.
            -- See https://cmp.saghen.dev/recipes.html#buffer-completion-from-all-open-buffers
            opts = {
              -- (Recommended) Filter to only "normal" buffers
              get_bufnrs = function()
                return vim.tbl_filter(function(bufnr)
                  return vim.bo[bufnr].buftype == ""
                end, vim.api.nvim_list_bufs())
              end,
            },
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 90,
          },
          lsp = {
            -- Default
            -- Filter text items from the LSP provider, since we have the buffer provider for that
            transform_items = function(_, items)
              return vim.tbl_filter(function(item)
                return item.kind ~= require("blink.cmp.types").CompletionItemKind.Text
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
        keymap = {
          preset = "none",
          -- stylua: ignore
          ["<A-k>"] = { function(cmp) return cmp.select_prev({ auto_insert = false }) end, "fallback", },
          -- stylua: ignore
          ["<A-j>"] = { function(cmp) return cmp.select_next({ auto_insert = false }) end, "fallback", },
          -- stylua: ignore
          ["<C-p>"] = { function(cmp) return cmp.select_prev({ auto_insert = false }) end, "fallback", },
          -- stylua: ignore
          ["<C-n>"] = { function(cmp) return cmp.select_next({ auto_insert = false }) end, "fallback", },
          -- stylua: ignore
          ["<Tab>"] = { function(cmp) return cmp.accept() end, "fallback", },
          -- stylua: ignore
          ["<CR>"] = { "fallback", },
          -- stylua: ignore
          ["<A-/>"] = { function(cmp) if cmp.is_menu_visible() then return cmp.hide() else return cmp.show() end end, "fallback", },
        },
      },
    },
  },

  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = {
      ---Use treesitter to highlight the label text for the given list of sources.
      "xzbdmw/colorful-menu.nvim",
    },
    opts = {
      completion = {
        menu = {
          draw = {
            -- We don't need label_description now because label and label_description are already combined together in
            -- label by colorful-menu.nvim.
            columns = { { "kind_icon" }, { "label", gap = 1 }, { "kind" } },
            components = {
              label = {
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(ctx)
                end,
              },
            },
          },
        },
      },
    },
  },

  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = {
      {
        "Kaiser-Yang/blink-cmp-dictionary",
        dependencies = { "nvim-lua/plenary.nvim" },
      },
    },
    opts = {
      sources = {
        -- Add 'dictionary' to the list
        default = { "dictionary" },
        providers = {
          dictionary = {
            score_offset = 5,
            module = "blink-cmp-dictionary",
            name = "Dict",
            -- Make sure this is at least 2.
            -- 3 is recommended
            min_keyword_length = 3,
            max_items = 10,
            opts = {
              -- options for blink-cmp-dictionary
              dictionary_directories = { "~/.config/nvim/dictionary" },
            },
          },
        },
      },
    },
  },

  -- Spell source based on Neovim's `spellsuggest`.
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "ribru17/blink-cmp-spell" },
    opts = {
      sources = {
        default = { "spell" },
        providers = {
          -- ...
          spell = {
            name = "Spell",
            module = "blink-cmp-spell",
            score_offset = 10,
            opts = {
              use_cmp_spell_sorting = true,
            },
          },
        },
      },
    },
  },

  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = {
      snippets = {
        preset = "luasnip",
      },
      sources = {
        default = { "snippets" },
        providers = {
          -- Hide snippets after trigger character
          -- Trigger characters are defined by the sources. For example, for Lua, the trigger characters are ., ", '.
          snippets = {
            score_offset = 80,
            should_show_items = function(ctx)
              return ctx.trigger.initial_kind ~= "trigger_character"
            end,
            fallbacks = { "buffer" },
          },
        },
      },
    },
  },
}
