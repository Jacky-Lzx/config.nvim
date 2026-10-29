return {
  {
    "Jacky-Lzx/lsp-tools.nvim",
    url = "git@github.com:Jacky-Lzx/lsp-tools.nvim.git",
    dev = true,
    dependencies = { "folke/snacks.nvim" },
    event = "LspAttach",
    cmd = { "Outline", "OutlineOpen", "LspToolsOutline", "LspToolsOutlineOpen", "LspToolsOutlineClose" },
    keys = {
      {
        "<leader>go",
        function()
          require("lsp-tools").toggle_outline()
        end,
        desc = "[LSP] Toggle outline",
        mode = "n",
      },
      {
        "]r",
        function()
          require("lsp-tools").jump_reference(vim.v.count1)
        end,
        desc = "[LSP] Next reference",
        mode = "n",
      },
      {
        "[r",
        function()
          require("lsp-tools").jump_reference(-vim.v.count1)
        end,
        desc = "[LSP] Previous reference",
        mode = "n",
      },
      {
        "<leader>a",
        function()
          require("lsp-tools").code_action()
        end,
        desc = "[LSP] Code action",
        mode = { "n", "x" },
      },
      {
        "<A-a>",
        function()
          require("lsp-tools").code_action()
        end,
        desc = "[LSP] Code action",
        mode = "i",
      },
    },
    opts = {
      outline = {
        width = 0.15,
        focus_on_open = false,
        icons = {
          Key = { icon = "󰌆", hl = "Type" },
          Event = { icon = "󱐋", hl = "Type" },
        },
      },
      rename = {
        backend = "delta",
        delta = {
          args = { "--file-style=omit", "--hunk-header-style=file line-number syntax" },
        },
      },
      code_actions = {
        backend = "delta", -- Set "vim" to use the native diff preview.
        delta = {
          args = {
            "--file-style=omit",
            "--hunk-header-style=file line-number syntax",
          },
        },
      },
    },
    config = function(_, opts)
      local tools = require("lsp-tools")
      tools.setup(opts)
      -- Preserve the previous outline commands during migration.
      vim.api.nvim_create_user_command("Outline", tools.toggle_outline, { force = true })
      vim.api.nvim_create_user_command("OutlineOpen", function()
        tools.open_outline()
      end, { force = true })
    end,
  },
}
