return {
  {
    -- Local-only until selection-tools has a published remote repository.
    dir = require("utils.platform").dev_plugin_root() .. "/selection-tools.nvim",
    name = "selection-tools.nvim",
    main = "selection_tools",
    lazy = false,
    priority = 900, -- Install vim.ui.select after Snacks has initialized.
    cmd = "SelectionTools",
    opts = {
      ui_select = true,
      matcher = { backend = "auto", threshold = 50000 },
      layout = {
        width = 0.8,
        min_width = 60,
        height = 0.9,
        border = "rounded",
        title_pos = "center",
        input_position = "bottom",
        reverse = true,
        preview_height = 0.6,
      },
      history = { persist = true },
      select = {
        layout = {
          width = 0.5,
          min_width = 80,
          max_width = 100,
          height = 0.4,
          input_position = "top",
          reverse = false,
        },
      },
      system_open = require("utils.platform").open,
      keys = {
        next = { "<A-j>", "<C-n>", "<Down>" },
        previous = { "<A-k>", "<C-p>", "<Up>" },
        select_previous = { "<Tab>" },
        select_next = { "<S-Tab>" },
        history_back = { "<A-Up>" },
        history_forward = { "<A-Down>" },
        preview_up = { "<C-u>" },
        preview_down = { "<C-d>" },
        list_up = { "<A-u>" },
        list_down = { "<A-d>" },
        copy = { "<C-y>" },
        system_open = { "<C-o>" },
        ignore = { "<C-j>", "<C-k>" },
      },
    },
    keys = {
      {
        "<leader>,",
        function()
          require("selection_tools").buffers()
        end,
        desc = "[Selection] Buffers",
      },
      {
        "<leader>sb",
        function()
          require("selection_tools").buffers()
        end,
        desc = "[Selection] Buffers",
      },
      {
        "<leader>sf",
        function()
          require("selection_tools").files()
        end,
        desc = "[Selection] Find files",
      },
    },
  },
}
