return {
  {
    "petertriho/nvim-scrollbar",
    branch = "v1",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      handle = {
        text = " ",
        blend = 60, -- Integer between 0 and 100. 0 for fully opaque and 100 to full transparent. Defaults to 30.
        color = nil,
        color_nr = nil, -- cterm
        highlight = "Visual",
        hide_if_all_visible = true, -- Hides handle if all lines are visible
      },
      handlers = {
        gitsigns = true, -- for gitsigns
        -- hlslens connects this handler on the first search.
        search = false,
      },
      excluded_buftypes = {
        "terminal",
        "nofile", -- This buftype is used by dap's hover() window
      },
      marks = {
        Search = {
          color = "#CBA6F7",
        },
        GitAdd = { text = "┃" },
        GitChange = { text = "┃" },
        GitDelete = { text = "_" },
      },
    },
    config = function(_, opts)
      require("scrollbar").setup(opts)
    end,
  },
}
