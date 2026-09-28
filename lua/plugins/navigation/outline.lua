return {
  {
    "hedyhli/outline.nvim",
    cmd = { "Outline", "OutlineOpen" },
    keys = {
      { "<leader>go", "<CMD>Outline<CR>", desc = "Toggle outline" },
    },
    opts = {
      outline_window = {
        width = 15, -- Relative width in percentage
        focus_on_open = false,
      },
      symbols = {
        -- The next fallback if both icon_fetcher and icon_source has failed, is
        -- the custom mapping of icons specified below. The icons table is also
        -- needed for specifying hl group.
        icons = {
          Key = { icon = "󰌆", hl = "Type" },
          Event = { icon = "󱐋", hl = "Type" },
        },
      },
    },
  },
}
