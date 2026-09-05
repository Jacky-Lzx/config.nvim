return {
  {
    "folke/trouble.nvim",
    -- NOTE: The plugin should be loaded when LSP is attached to enable the display of LSP document symbols.
    --       <2026.05.07, lzx>
    event = "LspAttach",
    cmd = "Trouble",
    opts = {
      focus = false,
      warn_no_results = false,
      open_no_results = true,
      preview = {
        type = "float",
        relative = "editor",
        border = "rounded",
        title = "Preview",
        title_pos = "center",
        ---`row` and `col` values relative to the editor
        position = { 0.3, 0.3 },
        size = { width = 0.6, height = 0.5 },
        zindex = 200,
      },
      icons = {
        ---@type trouble.Indent.symbols
        indent = {
          ws = " ",
        },
      },
    },

    -- stylua: ignore
    keys = {
      { "<leader>gd", "<cmd>Trouble diagnostics toggle<cr>",                         desc = "[Trouble] toggle buffer diagnostics" },
      { "<leader>gs", "<cmd>Trouble symbols toggle focus=false<cr>",                 desc = "[Trouble] toggle symbols " },
      { "<leader>gl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",  desc = "[Trouble] toggle LSP definitions/references/...", },
      { "<leader>gL", "<cmd>Trouble loclist toggle<cr>",                             desc = "[Trouble] Location List" },
      { "<leader>gq", "<cmd>Trouble qflist toggle<cr>",                              desc = "[Trouble] Quickfix List" },

      -- { "grr", "<CMD>Trouble lsp_references focus=true<CR>",         mode = { "n" }, desc = "[Trouble] LSP references" },
      -- { "gD", "<CMD>Trouble lsp_declarations focus=true<CR>",        mode = { "n" }, desc = "[Trouble] LSP declarations" },
      -- { "gd", "<CMD>Trouble lsp_type_definitions focus=true<CR>",    mode = { "n" }, desc = "[Trouble] LSP type definitions" },
      -- { "gri", "<CMD>Trouble lsp_implementations focus=true<CR>",    mode = { "n" }, desc = "[Trouble] LSP implementations" },
    },
  },

  -- Open snacks picker results in trouble.
  -- This config causes the trouble plugin to be loeaded when snacks.nvim is loaded.
  {
    "folke/trouble.nvim",
    optional = true,
    specs = {
      "folke/snacks.nvim",
      opts = function(_, opts)
        return vim.tbl_deep_extend("force", opts or {}, {
          picker = {
            -- NOTE: Copy from `require("trouble.sources.snacks").actions` to avoid the loading of trouble at startup
            -- <2026.04.14, lzx>
            actions = {
              -- Open selected or all items in the trouble list.
              trouble_open = {
                action = function()
                  require("trouble.sources.snacks").wrap({ type = "smart" })
                end,
                desc = "smart-open-with-trouble",
              },
            },
            win = {
              input = {
                keys = {
                  ["<c-t>"] = {
                    "trouble_open",
                    mode = { "n", "i" },
                  },
                },
              },
            },
          },
        })
      end,
    },
  },
}
