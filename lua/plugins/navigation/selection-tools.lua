return {
  {
    config = function(ctx)
      require("config.bindings").set("selection-tools.nvim", {
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
        {
          "<leader>sg",
          function()
            require("selection_tools").grep({ regex = true })
          end,
          desc = "[Selection] Grep",
        },
        {
          "<leader>sP",
          function()
            require("selection_tools").projects()
          end,
          desc = "[Selection] Projects",
        },
        {
          "<leader>sR",
          function()
            require("selection_tools").recent()
          end,
          desc = "[Selection] Recent",
        },
        {
          "<leader>sr",
          function()
            require("selection_tools").resume()
          end,
          desc = "[Selection] Resume",
        },
        {
          "<leader>st",
          function()
            require("selection_tools").todo_comments({
              keywords = { "TODO", "FIX", "FIXME", "BUG", "FIXIT", "HACK", "WARN", "ISSUE" },
            })
          end,
          desc = "[Selection] Todos (without NOTE)",
        },
        {
          "<leader>sT",
          function()
            require("selection_tools").todo_comments()
          end,
          desc = "[Selection] Todos (with NOTE)",
        },
        {
          '<leader>s"',
          function()
            require("selection_tools").registers()
          end,
          desc = "[Selection] Registers",
        },
        {
          "<leader>sj",
          function()
            require("selection_tools").jumps()
          end,
          desc = "[Selection] Jumps",
        },
        {
          "<leader>sm",
          function()
            require("selection_tools").marks()
          end,
          desc = "[Selection] Marks",
        },
        {
          "<leader>su",
          function()
            require("selection_tools").undo()
          end,
          desc = "[Selection] Undo history",
        },
        {
          "<leader>s/",
          function()
            require("selection_tools").search_history()
          end,
          desc = "[Selection] Search history",
        },
        {
          "<leader>s:",
          function()
            require("selection_tools").command_history()
          end,
          desc = "[Selection] Command history",
        },
        {
          "<leader>sq",
          function()
            require("selection_tools").qflist()
          end,
          desc = "[Selection] Quickfix list",
        },
        {
          "<leader>sl",
          function()
            require("selection_tools").loclist()
          end,
          desc = "[Selection] Location list",
        },
        {
          "<leader>sc",
          function()
            require("selection_tools").commands()
          end,
          desc = "[Selection] Commands",
        },
        {
          "<leader>sA",
          function()
            require("selection_tools").autocmds()
          end,
          desc = "[Selection] Autocmds",
        },
        {
          "<leader>sk",
          function()
            require("selection_tools").keymaps()
          end,
          desc = "[Selection] Keymaps",
        },
        {
          "<leader>sH",
          function()
            require("selection_tools").help()
          end,
          desc = "[Selection] Help pages",
        },
        {
          "<leader>sM",
          function()
            require("selection_tools").man()
          end,
          desc = "[Selection] Man pages",
        },
        {
          "<leader>sa",
          function()
            require("selection_tools").spelling({ layout = { min_width = 80 } })
          end,
          desc = "[Selection] Spelling",
        },
        {
          "<leader>sh",
          function()
            require("selection_tools").highlights()
          end,
          desc = "[Selection] Highlights",
        },
        {
          "<leader>sI",
          function()
            require("selection_tools").icons()
          end,
          desc = "[Selection] Icons",
        },
      })
      require("selection_tools").setup(ctx.opts)
    end,
    id = "selection-tools.nvim",
    source = "Jacky-Lzx/selection-tools.nvim",
    dev = true,
    main = "selection_tools",
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
      preview = {
        providers = {
          function(ctx)
            return require("selection_tools.integrations.image_tools").preview(ctx)
          end,
        },
      },
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
  },
}
