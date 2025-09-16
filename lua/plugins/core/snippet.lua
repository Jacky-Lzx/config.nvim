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
      -- { "<C-E>" , "luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'", mode = { "i", "s" }, silent = true, desc = "luasnip choise", remap = true, expr = true },
    },
    opts = function()
      local types = require("luasnip.util.types")
      return {
        -- update_events = { "TextChanged", "TextChangedI" },
        -- update_events = { "TextChanged" },
        link_children = true,
        link_roots = true,
        exit_roots = true,
        ---Events on which to leave the current snippet-root if the cursor is outside its' "region".
        ---Disabled by default, `'CursorMoved',` `'CursorHold'` or `'InsertEnter'` seem reasonable.
        region_check_events = { "CursorMoved", "CursorHold", "InsertEnter" },
        delete_check_events = { "TextChanged" },
        ---Whether snippet-roots should exit at reaching at their last node, `$0`.
        ---This setting is only valid for root snippets, not child snippets.
        ---This setting may avoid unexpected behavior by disallowing to jump earlier (finished) snippets.
        ---Check Basics-Snippet-Insertion for more information on snippet-roots.
        ext_opts = {
          [types.choiceNode] = {
            active = {
              virt_text = { { "", "BlinkCmpKindEnum" } },
            },
            snippet_passive = {
              virt_text = { { "", "BlinkCmpLabel" } },
            },
            passive = {
              virt_text = { { "", "BlinkCmpLabel" } },
            },
          },
          [types.insertNode] = {
            active = {
              virt_text = { { "󰗧", "BlinkCmpKindText" } },
              -- virt_text_pos = "inline",
            },
            snippet_passive = {
              virt_text = { { "󰗧", "BlinkCmpLabel" } },
              -- virt_text_pos = "inline",
            },
            passive = {
              virt_text = { { "󰗧", "BlinkCmpLabel" } },
              -- virt_text_pos = "inline",
            },
          },
        },
        ---Mapping for populating `TM_SELECTED_TEXT` and related variables (not set by default).
        cut_selection_keys = "`",
        store_selection_keys = "`",
        enable_autosnippets = true,
      }
    end,
    config = function(_, opts)
      require("luasnip").setup(opts)

      -- require("luasnip.loaders.from_vscode").lazy_load({ paths = { "./my_snippets/snippets" } }) -- Load snippets from my-snippets folder
      -- require("luasnip.loaders.from_vscode").lazy_load({ paths = { "./my_snippets/friendly-snippets" } })
      require("luasnip.loaders.from_lua").lazy_load({ paths = { "./lua/templates/snippets" } })

      local auto_expand = require("luasnip").expand_auto
      require("luasnip").expand_auto = function(...)
        vim.o.undolevels = vim.o.undolevels
        auto_expand(...)
      end

      -- local ls = require("luasnip")
      -- ls.filetype_extend("systemverilog", { "verilog" })

      vim.api.nvim_create_user_command("LuaSnipList", require("luasnip.extras.snippet_list").open, {})
      vim.api.nvim_create_user_command("LuaSnipEdit", require("luasnip.loaders").edit_snippet_files, {})

      -- vim.api.nvim_create_autocmd(opts.region_check_events, {
      --   callback = function()
      --     local ls = require("luasnip")
      --     if ls.get_active_snip() and not ls.in_snippet() then
      --       ls.unlink_current()
      --     end
      --   end,
      -- })
    end,
  },
}
