return {
  {
    "yetone/avante.nvim",
    enabled = false,
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- ⚠️ must add this setting! ! !
    build = vim.fn.has("win32") == 1 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make BUILD_FROM_SOURCE=true",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      -- "nvim-mini/mini.pick", -- for file_selector provider mini.pick
      -- "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      -- "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      -- "ibhagwan/fzf-lua", -- for file_selector provider fzf
      -- "stevearc/dressing.nvim", -- for input provider dressing
      "folke/snacks.nvim", -- for input provider snacks
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        optional = true,
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
    -- Configuration options: `https://github.com/yetone/avante.nvim/blob/main/lua/avante/config.lua`
    ---@type avante.Config
    opts = {
      -- add any opts here
      -- this file can contain specific instructions for your project
      instructions_file = "avante.md",
      -- for example
      provider = "claude",
      providers = {
        claude = {
          endpoint = "https://api.anthropic.com",
          model = "claude-sonnet-4-20250514",
          timeout = 30000, -- Timeout in milliseconds
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
        },
        moonshot = {
          endpoint = "https://api.moonshot.ai/v1",
          model = "kimi-k2-0711-preview",
          timeout = 30000, -- Timeout in milliseconds
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 32768,
          },
        },
      },
      selector = {
        --- @type avante.SelectorProvider
        provider = "snacks",
        -- Options override for custom providers
        provider_opts = {},
      },
      input = {
        provider = "snacks",
        provider_opts = {
          -- Additional snacks.input options
          title = "Avante Input",
          icon = " ",
        },
      },
      mappings = {
        ---@class AvanteConflictMappings
        diff = {
          ours = "co",
          theirs = "ct",
          all_theirs = "ca",
          both = "cb",
          cursor = "cc",
          next = "]x",
          prev = "[x",
        },
        suggestion = {
          accept = "<M-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
        jump = {
          next = "]]",
          prev = "[[",
        },
        submit = {
          normal = "<CR>",
          insert = "<C-s>",
        },
        cancel = {
          normal = { "<C-c>", "<Esc>", "q" },
          insert = { "<C-c>" },
        },
        -- The following will be safely set by avante.nvim
        ask = "<leader>caa",
        new_ask = "<leader>can",
        zen_mode = "<leader>caz",
        edit = "<leader>cae",
        refresh = "<leader>car",
        -- typos: ignore
        focus = "<leader>caf", -- codespell:ignore
        stop = "<leader>caS",
        toggle = {
          default = "<leader>cat",
          debug = "<leader>cad",
          selection = "<leader>caC",
          suggestion = "<leader>cas",
          repomap = "<leader>caR",
        },
        sidebar = {
          expand_tool_use = "<S-Tab>",
          next_prompt = "]p",
          prev_prompt = "[p",
          apply_all = "A",
          apply_cursor = "a",
          retry_user_request = "r",
          edit_user_request = "e",
          switch_windows = "<Tab>",
          reverse_switch_windows = "<S-Tab>",
          toggle_code_window = "x",
          remove_file = "d",
          add_file = "@",
          close = { "q" },
          ---@type AvanteCloseFromInput | nil
          close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
          ---@type AvanteToggleCodeWindowFromInput | nil
          toggle_code_window_from_input = nil, -- e.g., { normal = "x", insert = "<C-;>" }
        },
        files = {
          add_current = "<leader>cac", -- Add current buffer to selected files
          add_all_buffers = "<leader>caB", -- Add all buffer files to selected files
        },
        select_model = "<leader>ca?", -- Select model command
        select_history = "<leader>cah", -- Select history command
        confirm = {
          focus_window = "<C-w>f",
          code = "c",
          resp = "r",
          input = "i",
        },
      },
      windows = {
        width = 40, -- default % based on available width in vertical layout
        sidebar_header = {
          enabled = true, -- true, false to enable/disable the header
        },
        edit = {
          border = { " ", " ", " ", " ", " ", " ", " ", " " },
          start_insert = false, -- Start insert mode when opening the edit window
        },
        ask = {
          floating = false, -- Open the 'AvanteAsk' prompt in a floating window
          border = { " ", " ", " ", " ", " ", " ", " ", " " },
          start_insert = false, -- Start insert mode when opening the ask window
          ---@type AvanteInitialDiff
          focus_on_apply = "ours", -- which diff to focus after applying
        },
      },
      selection = {
        hint_display = "none",
      },
    },
  },
  {
    -- Solve the display issue with lualine
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = {
      options = {
        disabled_filetypes = {
          -- winbar = { "AvanteInput", "AvanteTodos", "AvanteSelectedFiles", "AvanteSelectedCode", "Avante" },
          -- statusline = { "AvanteInput", "AvanteTodos", "AvanteSelectedFiles", "AvanteSelectedCode", "Avante" },
        },
      },
    },
  },
}
