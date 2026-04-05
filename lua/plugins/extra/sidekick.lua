vim.lsp.enable("copilot")

return {
  {
    "folke/sidekick.nvim",
    opts = {
      nes = {
        clear = {
          -- events that clear the current next edit suggestion
          events = { "TextChangedI", "InsertEnter" },
          esc = false, -- clear next edit suggestions when pressing <Esc>
        },
      },
      cli = {
        mux = {
          backend = "tmux",
          enabled = false,
        },
      },
    },
    -- Hello World of Keybindings! Here's how you can set up some keybindings for Sidekick. You can customize these to fit your workflow.
    keys = {
      {
        "<leader>cn",
        function()
          -- if there is a next edit, jump to it, otherwise apply it if any
          -- require("sidekick").nes_jump_or_apply()
          require("sidekick.nes").apply()
        end,
        expr = true,
        desc = "Apply Next Edit Suggestion",
      },
    },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "copilot-language-server" } },
  },
}
