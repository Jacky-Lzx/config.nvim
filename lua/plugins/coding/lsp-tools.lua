return {
  {
    "Jacky-Lzx/lsp-tools.nvim",
    url = "git@github.com:Jacky-Lzx/lsp-tools.nvim.git",
    dev = true,
    dependencies = { "folke/snacks.nvim" },
    event = "LspAttach",
    cmd = { "Outline", "OutlineOpen", "LspToolsOutline", "LspToolsOutlineOpen", "LspToolsOutlineClose", "LspToolsInfo" },
    keys = {
      {
        "<leader>gd",
        function()
          require("lsp-tools").diagnostics({ toggle = true })
        end,
        desc = "[LSP] Toggle diagnostic overview",
      },
      {
        "<leader>gl",
        function()
          require("lsp-tools").locations({ toggle = true, position = "right", focus = false })
        end,
        desc = "[LSP] Toggle definitions/references",
      },
      {
        "<leader>gL",
        function()
          require("lsp-tools").loclist({ toggle = true })
        end,
        desc = "[LSP] Toggle location list",
      },
      {
        "<leader>gq",
        function()
          require("lsp-tools").quickfix({ toggle = true })
        end,
        desc = "[LSP] Toggle quickfix list",
      },
      {
        "<leader>gT",
        function()
          require("lsp-tools").type_hierarchy()
        end,
        desc = "[LSP] Type hierarchy",
      },
      {
        "<leader>g?",
        function()
          require("lsp-tools").inspect()
        end,
        desc = "[LSP] Inspect clients and requests",
      },
      {
        "<leader>gH",
        function()
          require("lsp-tools").hover()
        end,
        desc = "[LSP] Pin hover documentation",
      },
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
      lightbulb = true,
      linked_editing = true,
      diagnostics = true,
      results = true,
      hover = true,
      inspect = true,
      hierarchy = true,
      links = {
        fallback = function()
          require("utils.open").open_at_cursor()
        end,
      },
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
      vim.api.nvim_create_user_command("LspToolsInfo", function()
        tools.inspect()
      end, { force = true })
      -- Preserve the previous outline commands during migration.
      vim.api.nvim_create_user_command("Outline", tools.toggle_outline, { force = true })
      vim.api.nvim_create_user_command("OutlineOpen", function()
        tools.open_outline()
      end, { force = true })
    end,
  },
  {
    "folke/snacks.nvim",
    optional = true,
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts or {}, {
        picker = {
          actions = {
            results_open = {
              action = function(picker)
                require("lsp-tools").from_picker(picker, { type = "smart" })
              end,
              desc = "Open results in LSP tools",
            },
          },
          win = {
            input = {
              keys = {
                ["<c-t>"] = { "results_open", mode = { "n", "i" } },
              },
            },
          },
        },
      })
    end,
  },
}
