return {
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = {
      ---Use treesitter to highlight the label text for the given list of sources.
      "xzbdmw/colorful-menu.nvim",
    },
    opts = {
      completion = {
        menu = {
          draw = {
            -- We don't need label_description now because label and label_description are already combined together in
            -- label by colorful-menu.nvim.
            columns = { { "kind_icon" }, { "label", gap = 1 }, { "kind" } },
            components = {
              label = {
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(ctx)
                end,
              },
            },
          },
        },
      },
    },
  },
}
