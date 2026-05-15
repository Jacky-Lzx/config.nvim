return {
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      -- NOTE: The barbar.nvim should be started before the nvim-tree.
      --         Otherwise when opening files, the bufferline will not show. <2026.04.30, lzx>
      {
        "romgrk/barbar.nvim",
        optional = true,
        opts = {
          -- Set the filetypes which barbar will offset itself for
          sidebar_filetypes = {
            -- Default values: {event = 'BufWinLeave', text = '', align = 'left'}
            NvimTree = { text = "NvimTree", event = "BufWinLeave", align = "center" },
          },
        },
      },
    },
    keys = {
      { "<leader>e", "<CMD>NvimTreeToggle<CR>", mode = { "n" }, desc = "[NvimTree] Toggle NvimTree" },
    },
    opts = {
      -- keep the cursor on the first letter of the filename when moving in the tree.
      hijack_cursor = true,
      view = {
        signcolumn = "no",
        width = 40,
      },
      update_focused_file = {
        enable = true,
      },
      notify = {
        threshold = vim.log.levels.WARN,
      },
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")

        local function opts(desc)
          return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        -- default mappings
        api.map.on_attach.default(bufnr)

        -- custom mappings
        vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
        vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("Close Directory"))
      end,
    },
  },

  {
    "antosha417/nvim-lsp-file-operations",
    event = "LspAttach",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Uncomment whichever supported plugin(s) you use
      "nvim-tree/nvim-tree.lua",
      -- "nvim-neo-tree/neo-tree.nvim",
      -- "simonmclean/triptych.nvim"
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
}
