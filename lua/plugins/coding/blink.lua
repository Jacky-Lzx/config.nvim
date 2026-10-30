return {
  { import = "plugins.coding.completion.core" },
  { import = "plugins.coding.completion.menu" },
  { import = "plugins.coding.completion.dictionary" },
  { import = "plugins.coding.completion.spell" },
  { import = "plugins.coding.completion.snippets" },
  {
    "saghen/blink.cmp",
    optional = true,
    -- Apply after the fragments so existing completion policies are preserved.
    opts = function(_, opts)
      opts.sources = require("input-tools.blink").sources_config(opts.sources)
      opts.completion = opts.completion or {}
      local menu = opts.completion.menu or {}
      opts.completion.menu = vim.tbl_deep_extend(
        "force", menu, require("input-tools.blink").menu_config(menu)
      )
    end,
  },
}
