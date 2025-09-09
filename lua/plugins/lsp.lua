local utils = require("utils.utils")

-- local signs = { Error = "", Warn = "", Hint = "", Info = "" }
local signs = { Error = "", Warn = "", Hint = "󰌶", Info = "" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

local virtual_text_config_enabled = {
  spacing = 4,
  -- format = function(_)
  --   return ""
  -- end,
  prefix = function(diagnostic)
    if diagnostic.severity == vim.diagnostic.severity.ERROR then
      return ""
    elseif diagnostic.severity == vim.diagnostic.severity.WARN then
      return ""
    elseif diagnostic.severity == vim.diagnostic.severity.INFO then
      return ""
    elseif diagnostic.severity == vim.diagnostic.severity.HINT then
      return "󰌶"
    end
    return diagnostic.message
  end,
}

local virtual_text_config_disabled = {
  spacing = 0,
  format = function(_)
    return ""
  end,
  prefix = function(diagnostic)
    if diagnostic.severity == vim.diagnostic.severity.ERROR then
      return ""
    elseif diagnostic.severity == vim.diagnostic.severity.WARN then
      return ""
    elseif diagnostic.severity == vim.diagnostic.severity.INFO then
      return ""
    elseif diagnostic.severity == vim.diagnostic.severity.HINT then
      return "󰌶"
    end
    return diagnostic.message
  end,
}

local signs_config = {
  text = {
    [vim.diagnostic.severity.ERROR] = "",
    [vim.diagnostic.severity.WARN] = "",
    [vim.diagnostic.severity.INFO] = "",
    [vim.diagnostic.severity.HINT] = "󰌶",
  },
  severity = {
    vim.diagnostic.severity.ERROR,
    vim.diagnostic.severity.WARN,
    vim.diagnostic.severity.INFO,
    vim.diagnostic.severity.HINT,
  },
}

local virtual_lines_config = { current_line = true }
vim.diagnostic.config({
  underline = false,
  signs = signs_config,
  update_in_insert = false,
  virtual_text = virtual_text_config_enabled,
  virtual_lines = false,
  severity_sort = true,
  float = {
    border = "rounded",
  },
})

local snacks = require("snacks")

snacks.toggle.diagnostics():map("<leader>td")
snacks.toggle
  .new({
    id = "virtual_lines",
    name = "Virtual lines",
    get = function()
      return not not vim.diagnostic.config().virtual_lines
    end,
    set = function(state)
      if state then
        vim.diagnostic.config({ virtual_lines = virtual_lines_config })
      else
        vim.diagnostic.config({ virtual_lines = false })
      end
    end,
  })
  :map("<leader>tV")
snacks.toggle
  .new({
    id = "virtual_text",
    name = "Virtual text",
    get = function()
      return vim.diagnostic.config().virtual_text.format == virtual_text_config_enabled.format
    end,
    set = function(state)
      if state then
        vim.diagnostic.config({ virtual_text = virtual_text_config_enabled })
      else
        vim.diagnostic.config({ virtual_text = virtual_text_config_disabled })
      end
    end,
  })
  :map("<leader>tv")

-- TODO remove
-- put this VERY early (before plugins are loaded)
-- see https://github.com/folke/trouble.nvim/issues/655
-- until fixed, use this to leave all of trouble working, just without its TS decoration
-- helper; so, :Trouble commands work; no decoration provider gets registered.
package.preload["trouble.view.treesitter"] = function()
  local M = {}
  function M.setup(_) end
  function M.is_enabled()
    return false
  end
  function M.enable()
    return false
  end
  function M.attach(_) end
  function M.detach(_) end
  -- Neovim decoration provider callbacks (no-op)
  function M.on_start(_) end
  function M.on_buf(_) end
  function M.on_win(_) end
  function M.on_line(_) end
  function M.on_end(_) end
  function M.on_reload(_) end
  function M.on_lines(_) end
  return M
end

return {
  {
    "folke/trouble.nvim",
    event = "LspAttach",
    cmd = "Trouble",

    ---Open snacks picker results in trouble
    specs = {
      "folke/snacks.nvim",
      opts = function(_, opts)
        return vim.tbl_deep_extend("force", opts or {}, {
          picker = {
            actions = require("trouble.sources.snacks").actions,
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
    },

    -- stylua: ignore
    keys = {
      { "<A-j>", function() vim.diagnostic.jump({ count = 1 }) end,  mode = {"n"},   desc = "Go to next diagnostic"},
      { "<A-k>", function() vim.diagnostic.jump({ count = -1 }) end, mode = {"n"},   desc = "Go to previous diagnostic"},
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
    config = function(_, opts)
      require("trouble").setup(opts)
      local symbols = require("trouble").statusline({
        mode = "lsp_document_symbols",
        groups = {},
        title = false,
        filter = { range = true },
        format = "{kind_icon}{symbol.name:Normal}",
        -- The following line is needed to fix the background color
        -- Set it to the lualine section you want to use
        -- hl_group = "lualine_b_normal",
      })

      -- Insert status into lualine
      opts = require("lualine").get_config()
      table.insert(opts.winbar.lualine_b, 1, {
        symbols.get,
        cond = symbols.has,
      })
      require("lualine").setup(opts)
    end,
  },

  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "InsertEnter",
  --   opts = {
  --     bind = true,
  --     handler_opts = {
  --       border = "rounded",
  --     },
  --   },
  --   -- stylua: ignore
  --   keys = {
  --     { "gk", function() vim.lsp.buf.signature_help()  end, mode = { "n" }, desc = "toggle signature", noremap = true, silent = true },
  --     -- No use
  --     -- { "<C-i>", function() require("lsp_signature").toggle_float_win() end, mode = { "i" }, desc = "toggle signature", noremap = true, silent = true },
  --   },
  --   config = function(_, opts)
  --     require("lsp_signature").setup(opts)
  --   end,
  -- },
  -- cmdline tools and lsp servers
  {

    "mason-org/mason.nvim",
    event = "VeryLazy",
    -- keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {},
    },
    ---@param opts MasonSettings | {ensure_installed: string[]}
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")

      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },

  -- formatters
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    keys = {},
    opts = {
      format_on_save = function(_)
        -- Disable with a global or buffer-local variable
        if vim.g.enable_autoformat then
          return { timeout_ms = 500, lsp_format = "fallback" }
        end
      end,
    },
    init = function()
      vim.g.enable_autoformat = true
      require("snacks").toggle
        .new({
          id = "auto_format",
          name = "Auto format",
          get = function()
            return vim.g.enable_autoformat
          end,
          set = function(state)
            vim.g.enable_autoformat = state
          end,
        })
        :map("<leader>tf")
    end,
    config = function(_, opts)
      opts["formatters_by_ft"] =
        vim.tbl_extend("error", opts["formatters_by_ft"], utils.language_setup(G.language.formatter))
      opts["formatters_by_ft"].javascript = { "prettierd", "prettier", stop_after_first = true }
      opts["formatters_by_ft"]["_"] = { "trim_whitespace" }

      require("conform").setup(opts)
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost" },
    dependencies = {
      {
        "mason-org/mason.nvim",
        optional = true,
        opts_extend = { "ensure_installed" },
        opts = {
          ensure_installed = { "codespell", "typos" },
        },
      },
    },
    config = function(_, opts)
      require("lint").linters_by_ft =
        vim.tbl_deep_extend("error", opts["linters_by_ft"], utils.language_setup(G.language.linter))
      require("lint").linters_by_ft["fish"] = { "fish" }
      require("lint").linters_by_ft["bash"] = { "bash" }

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          -- try_lint without arguments runs the linters defined in `linters_by_ft`
          -- for the current filetype
          require("lint").try_lint()

          -- You can call `try_lint` with a linter name or a list of names to always
          -- run specific linters, independent of the `linters_by_ft` configuration
          require("lint").try_lint("codespell")
          require("lint").try_lint("typos")
        end,
      })
    end,
  },

  {
    -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
      -- { "folke/neodev.nvim", opts = { experimental = { pathStrict = true } } },
      "williamboman/mason-lspconfig.nvim",
      -- "hrsh7th/cmp-nvim-lsp",
      -- "SmiteshP/nvim-navic",
      -- Show lsp status on the bottom-left
      "j-hui/fidget.nvim",
      "saghen/blink.cmp",
    },
    opts = {},
    config = function(_, _)
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "rust_analyzer", "marksman", "pyright" },
        automatic_enable = false,
      })

      local extra = {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      }
      -- require("snacks.debug").inspect(extra.capabilities)

      utils.language_setup(G.language.lsp, extra)

      -- require("lspconfig").ltex.setup({})

      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      vim.lsp.config("typos_lsp", {
        settings = {
          typos_lsp = {
            init_options = {
              -- Custom config. Used together with a config file found in the workspace or its parents,
              -- taking precedence for settings declared in both.
              -- Equivalent to the typos `--config` cli argument.
              -- config = "~/code/typos-lsp/crates/typos-lsp/tests/typos.toml",
              -- How typos are rendered in the editor, can be one of an Error, Warning, Info or Hint.
              -- Defaults to error.
              diagnosticSeverity = "Hint",
            },
          },
        },
      })
      -- WARN:this lsp will cause a strange error when opening a markdown file with snacks.picker
      -- vim.lsp.enable("typos_lsp")

      -- Use LspAttach autocommand to only map the following keys
      -- after the language server attaches to the current buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Buffer local mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          -- local opts_local = { buffer = ev.buf }
          -- vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
          -- vim.keymap.set("n", "gd", vim.lsp.buf.definition)
          -- vim.keymap.set("n", "K", vim.lsp.buf.hover) -- defined in nvim-ufo
          -- vim.keymap.set("n", "gi", vim.lsp.buf.implementation)
          vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, {
            buffer = ev.buf,
            desc = "[LSP] Show diagnostic",
          })
          vim.keymap.set("n", "<leader>gk", vim.lsp.buf.signature_help, { desc = "[LSP] Signature help" })
          vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, { desc = "[LSP] Add workspace folder" })
          vim.keymap.set(
            "n",
            "<leader>wr",
            vim.lsp.buf.remove_workspace_folder,
            { desc = "[LSP] Remove workspace folder" }
          )
          vim.keymap.set("n", "<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, { desc = "[LSP] List workspace folders" })
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = ev.buf, desc = "[LSP] Rename" })
          -- vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts_local)
          -- vim.keymap.set("n", "gr", vim.lsp.buf.references, opts_local)
        end,
      })
    end,
  },
}
