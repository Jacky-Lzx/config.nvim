return {
  {
    -- Conflict with vscode_nvim, don't know why
    "kevinhwang91/nvim-hlslens",
    -- stylua: ignore
    keys = {
      { "n",  "nzz<CMD>lua require('hlslens').start()<CR>", mode = "n", desc = "Next match",      noremap = true, silent = true },
      { "N",  "Nzz<CMD>lua require('hlslens').start()<CR>", mode = "n", desc = "Previous match",  noremap = true, silent = true },
      { "*",  "*<CMD>lua require('hlslens').start()<CR>",   mode = "n", desc = "Next match",      noremap = true, silent = true },
      { "#",  "#<CMD>lua require('hlslens').start()<CR>",   mode = "n", desc = "Previous match",  noremap = true, silent = true },
      { "g*", "g*<CMD>lua require('hlslens').start()<CR>",  mode = "n", desc = "Next match",      noremap = true, silent = true },
      { "g#", "g#<CMD>lua require('hlslens').start()<CR>",  mode = "n", desc = "Previous match",  noremap = true, silent = true },
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
    end,
  },
}
