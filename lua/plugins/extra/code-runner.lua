return {
  {
    "michaelb/sniprun",
    branch = "master",

    build = "sh install.sh",
    cmd = { "SnipRun" },
    -- do 'sh install.sh 1' if you want to force compile locally
    -- (instead of fetching a binary from the github release). Requires Rust >= 1.65
    opts = {},
  },

  {
    "stevearc/overseer.nvim",
    dependencies = {
      {
        "rmagatti/auto-session",
        optional = true,
        opts_extend = { "close_filetypes_on_save" },
        opts = { close_filetypes_on_save = { "OverseerList" } },
      },
      {
        "folke/which-key.nvim",
        optional = true,
        opts = {
          spec = {
            { "<leader>o", group = "[Overseer]" },
          },
        },
      },
    },
    cmd = "OverseerRun",
    keys = {
      -- Shift+F5
      { "<F17>", "<CMD>OverseerRun<CR>", desc = "[Overseer] Run" },
      { "<leader>or", "<CMD>OverseerRun<CR>", desc = "[Overseer] Run" },
      -- typos: ignore
      { "<leader>ot", "<CMD>OverseerToggle<CR>", desc = "[Overseer] Toggle" }, -- codespell:ignore ot
    },

    opts = {
      task_list = {
        -- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        -- min_width and max_width can be a single value or a list of mixed integer/float types.
        -- max_width = {100, 0.2} means "the lesser of 100 columns or 20% of total"
        max_width = { 100, 0.6 },
        -- min_width = {40, 0.1} means "the greater of 40 columns or 10% of total"
        min_width = { 60, 0.4 },
        -- optionally define an integer/float for the exact width of the task list
        width = nil,
        max_height = { 30, 0.4 },
        min_height = 10,
        height = nil,
        -- String that separates tasks
        separator = "────────────────────────────────────────",
        -- Default direction. Can be "left", "right", or "bottom"
        direction = "bottom",
        -- Set keymap to false to remove default behavior
        -- You can add custom keymaps here as well (anything vim.keymap.set accepts)
        bindings = {
          ["<A-l>"] = "IncreaseDetail",
          ["<A-h>"] = "DecreaseDetail",
          ["<A-k>"] = "ScrollOutputUp",
          ["<A-j>"] = "ScrollOutputDown",
          ["<C-j>"] = false,
          ["<C-k>"] = false,
        },
      },
      bundles = {
        -- Disable autostart tasks when they are loaded from a bundle. If it is set to true, when restoring a session
        -- using auto-session, a task will be run at the start
        -- NOTE: even setting this option to false will auto start a task, if previously exiting neovim with
        -- OverseerList open
        autostart_on_load = false,
      },
    },
    config = function(_, opts)
      require("overseer").setup(opts)

      -- Insert status into lualine
      opts = require("lualine").get_config()
      table.insert(opts.sections.lualine_x, 1, "overseer")
      require("lualine").setup(opts)
    end,
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      require("overseer").enable_dap()
    end,
  },
}
