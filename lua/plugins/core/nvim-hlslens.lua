return {
  {
    -- Conflicted with vscode_nvim, don't know why
    "kevinhwang91/nvim-hlslens",
    -- stylua: ignore
    keys = {
      { "n",  "nzz<Cmd>lua require('hlslens').start()<CR>", mode = "n", desc = "Next match",      noremap = true, silent = true },
      { "N",  "Nzz<Cmd>lua require('hlslens').start()<CR>", mode = "n", desc = "Previous match",  noremap = true, silent = true },
      { "*",  "*<Cmd>lua require('hlslens').start()<CR>",   mode = "n", desc = "Next match",      noremap = true, silent = true },
      { "#",  "#<Cmd>lua require('hlslens').start()<CR>",   mode = "n", desc = "Previous match",  noremap = true, silent = true },
      { "g*", "g*<Cmd>lua require('hlslens').start()<CR>",  mode = "n", desc = "Next match",      noremap = true, silent = true },
      { "g#", "g#<Cmd>lua require('hlslens').start()<CR>",  mode = "n", desc = "Previous match",  noremap = true, silent = true },
      -- Clear search, diff update and redraw
      -- taken from LazyVim
      { "//", "<CMD>nohlsearch<BAR>diffupdate<BAR>normal! <C-L><CR>", mode = "n", desc = "Clear highlight", noremap = true, silent = true },

      { "/" },
      { "?" },
    },
    opts = {
      nearest_only = true,
    },
    config = function(_, opts)
      require("hlslens").setup(opts)
      -- nvim-scrollbar integration
      require("scrollbar.handlers.search").setup(opts)

      -- Set vim highlight group for HlSearchLens
      vim.api.nvim_set_hl(0, "HlSearchLens", { link = "CurSearch" })
      vim.api.nvim_set_hl(0, "HlSearchLensNear", { link = "CurSearch" })
    end,
  },
}
