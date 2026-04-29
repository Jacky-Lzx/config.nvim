return {
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    -- version = "v2.*",
    version = "*",
    -- install jsregexp (optional!:).
    build = "make install_jsregexp",
    -- stylua: ignore
    keys = {
      -- { "<A-n>" , function() require('luasnip').expand() end,                         mode = { "i", "s" }, silent = true, desc = "luasnip expand" },
      { "<A-l>" , function() require('luasnip').jump(1) end,                         mode = { "i", "s" }, silent = true, desc = "luasnip jump 1" },
      { "<A-h>" , function() require('luasnip').jump(-1) end,                        mode = { "i", "s" }, silent = true, desc = "luasnip jump -1" },
      { "<A-j>" , function() local ls = require('luasnip'); if ls.choice_active() then ls.change_choice(1) end end,                mode = { "i", "s" }, silent = true, desc = "luasnip jump 1" },
      { "<A-k>" , function() local ls = require('luasnip'); if ls.choice_active() then ls.change_choice(-1) end end,               mode = { "i", "s" }, silent = true, desc = "luasnip jump -1" },
      { "<A-i>" , function() require("luasnip.extras.select_choice")() end,               mode = { "i", "s" }, silent = true, desc = "choice selection" },
      -- { "<C-E>" , "luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'", mode = { "i", "s" }, silent = true, desc = "luasnip choice", remap = true, expr = true },
    },
    opts = function()
      local types = require("luasnip.util.types")
      return {
        link_roots = true,
        -- Whether snippet-roots should exit at reaching at their last node, `$0`.
        --   This setting is only valid for root snippets, not child snippets.
        --   This setting may avoid unexpected behavior by disallowing to jump earlier (finished) snippets.
        --   Check Basics-Snippet-Insertion for more information on snippet-roots.
        exit_roots = true,
        link_children = true,
        -- Events on which to leave the current snippet-root if the cursor is outside its' "region".
        --   Disabled by default, `'CursorMoved',` `'CursorHold'` or `'InsertEnter'` seem reasonable.
        region_check_events = { "CursorMoved", "CursorHold", "InsertEnter" },
        delete_check_events = { "TextChanged", "InsertLeave" },

        -- Mapping for populating `TM_SELECTED_TEXT` and related variables (not set by default).
        cut_selection_keys = "`",

        ext_opts = {
          [types.choiceNode] = {
            active = {
              virt_text = { { "", "BlinkCmpKindEnum" } },
              sign_text = "",
              sign_hl_group = "BlinkCmpKindEnum",
            },
            passive = {
              virt_text = { { "", "BlinkCmpLabel" } },
              sign_text = "",
              sign_hl_group = "BlinkCmpLabel",
            },
          },
          [types.insertNode] = {
            active = {
              virt_text = { { "", "BlinkCmpKindText" } },
              sign_text = "",
              sign_hl_group = "BlinkCmpKindText",
            },
            passive = {
              virt_text = { { "", "BlinkCmpLabel" } },
              sign_text = "",
              sign_hl_group = "BlinkCmpLabel",
            },
          },
        },
        store_selection_keys = "`",
        -- Autosnippets are disabled by default to minimize performance penalty if unused.
        enable_autosnippets = true,
      }
    end,
    config = function(_, opts)
      local ls = require("luasnip")
      ls.setup(opts)

      require("luasnip.loaders.from_lua").lazy_load({ paths = { "./lua/templates/snippets" } })

      -- NOTE: Adding undo point in `expand_auto` will lead to neovim recording every character you type in an expansion trigger.
      --       (https://github.com/L3MON4D3/LuaSnip/issues/830#issuecomment-1489967687) <2026.04.28, lzx>
      -- local auto_expand = ls.expand_auto
      -- ls.expand_auto = function(...)
      --   vim.print("hello world")
      --   vim.o.undolevels = vim.o.undolevels
      --   ---@diagnostic disable-next-line: redundant-parameter
      --   auto_expand(...)
      -- end

      -- -- NOTE: This can undo snippet that is expanded manually. It cannot undo autosnippets <2026.04.29, lzx>
      local snip_expand = ls.snip_expand
      ls.snip_expand = function(...)
        vim.o.undolevels = vim.o.undolevels
        snip_expand(...)
      end

      ls.filetype_extend("markdown", { "tex" })
      ls.filetype_extend("markdown_inline", { "markdown" })

      vim.api.nvim_create_user_command("LuaSnipList", require("luasnip.extras.snippet_list").open, {})
      vim.api.nvim_create_user_command("LuaSnipEdit", require("luasnip.loaders").edit_snippet_files, {})

      ls.log.set_loglevel("info")
    end,
  },
}
