local servers = {}
for _, name in ipairs(require("languages").current().servers) do
  servers[name] = true
end

return {
  {
    "Jacky-Lzx/lsp-tools.nvim",
    url = "git@github.com:Jacky-Lzx/lsp-tools.nvim.git",
    dev = true,
    -- Register servers before attachment; keep empty-editor startup lightweight.
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "neovim/nvim-lspconfig",
      -- Completion's capability API is available without initializing its UI.
      "file-tools.nvim",
      "toolchain-tools.nvim",
    },
    -- Picker and diff backends load through their APIs on first use.
    cmd = { "Outline", "OutlineOpen", "LspToolsOutline", "LspToolsOutlineOpen", "LspToolsOutlineClose", "LspToolsInfo" },
    keys = {
      {
        "gd",
        function()
          require("lsp-tools").lsp_definitions()
        end,
        desc = "[LSP] Goto definition",
      },
      {
        "gD",
        function()
          require("lsp-tools").lsp_declarations()
        end,
        desc = "[LSP] Goto declaration",
      },
      {
        "gi",
        function()
          require("lsp-tools").lsp_references()
        end,
        desc = "[LSP] References",
      },
      {
        "gI",
        function()
          require("lsp-tools").lsp_implementations()
        end,
        desc = "[LSP] Goto implementation",
      },
      {
        "gy",
        function()
          require("lsp-tools").lsp_type_definitions()
        end,
        desc = "[LSP] Goto type definition",
      },
      {
        "<leader>ss",
        function()
          require("lsp-tools").lsp_symbols()
        end,
        desc = "[LSP] Document symbols",
      },
      {
        "<leader>sS",
        function()
          require("lsp-tools").lsp_workspace_symbols()
        end,
        desc = "[LSP] Workspace symbols",
      },
      {
        "<leader>sd",
        function()
          require("lsp-tools").pick_diagnostics()
        end,
        desc = "[LSP] Search diagnostics",
      },
      {
        "<leader>sD",
        function()
          require("lsp-tools").pick_diagnostics({ scope = "buffer" })
        end,
        desc = "[LSP] Search buffer diagnostics",
      },
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
      server_activation = "filetype",
      servers = servers,
      lightbulb = true,
      linked_editing = true,
      diagnostics = true,
      pickers = true,
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
        backend = "native",
        native = { file_header = false },
      },
      code_actions = {
        backend = "native", -- Set "delta" for the optional ANSI renderer.
        native = { file_header = false },
      },
    },
    config = function(_, opts)
      vim.lsp.config("*", {
        capabilities = vim.tbl_deep_extend(
          "force",
          {},
          require("completion-tools").get_lsp_capabilities(),
          require("file_tools").capabilities()
        ),
      })
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
