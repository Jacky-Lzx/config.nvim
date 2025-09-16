-- FIXME: A temporary fix to trouble.nvim
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
    cmd = "Trouble",

    -- Open snacks picker results in trouble.
    -- This config causes the trouble plugin to be loeaded when snacks.nvim is loaded.
    specs = {
      {
        "folke/snacks.nvim",
        opts = function(_, opts)
          return vim.tbl_deep_extend("force", opts or {}, {
            picker = {
              actions = require("trouble.sources.snacks").actions,
              win = {
                input = {
                  keys = {
                    ["<c-t>"] = { "trouble_open", mode = { "n", "i" } },
                  },
                },
              },
            },
          })
        end,
      },
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
}
