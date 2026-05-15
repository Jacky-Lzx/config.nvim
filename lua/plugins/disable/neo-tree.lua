return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    -- lazy = false, -- neo-tree will lazily load itself
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    keys = {
      { "<leader>e", "<CMD>Neotree toggle<CR>", mode = { "n" }, desc = "[Neotree] Toggle Neotree" },
    },
    opts = {
      sources = { "filesystem", "buffers", "git_status" },
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
      filesystem = {
        -- bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
        },
        window = {
          mappings = {
            ["s"] = "system_open",
            ["<space>"] = "none",
            ["H"] = "none",
            ["h"] = "close_node",
            ["l"] = "toggle_node",
            ["<"] = "prev_source",
            ["Y"] = {
              function(state)
                local node = state.tree:get_node()
                local path = node:get_id()
                vim.fn.setreg("+", path, "c")
              end,
              desc = "Copy Path to Clipboard",
            },
          },
        },
      },

      commands = {
        system_open = function(state)
          local node = state.tree:get_node()
          local path = node:get_id()
          -- macOs: open file in default application in the background.
          vim.fn.jobstart({ "open", path }, { detach = true })
        end,
      },
      default_component_configs = {
        git_status = {
          symbols = {
            -- Change type
            added = "", -- or "✚"
            modified = "", -- or ""
            deleted = "✖", -- this can only be used in the git_status source
            renamed = "󰁕", -- this can only be used in the git_status source
            -- Status type
            untracked = "",
            ignored = "",
            unstaged = "󰄱",
            staged = "",
            conflict = "",
          },
        },
      },
    },
  },

  {
    "antosha417/nvim-lsp-file-operations",
    keys = { { "<leader>e" } }, -- Only load when <leader>e is pressed, which is the keybinding for toggling Neo-tree.
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim", -- makes sure that this loads after Neo-tree.
    },
    opts = true,
  },

  {
    "romgrk/barbar.nvim",
    optional = true,
    opts = {
      -- Set the filetypes which barbar will offset itself for
      sidebar_filetypes = {
        ["neo-tree"] = { text = "Neo-Tree", event = "BufWipeout", align = "center" },
      },
    },
  },
}
