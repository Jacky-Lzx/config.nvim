return {
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      snippets = {
        preset = "luasnip",
      },
      sources = {
        default = { "snippets" },
        providers = {
          -- Hide snippets after trigger character
          -- Trigger characters are defined by the sources. For example, for Lua, the trigger characters are ., ", '.
          snippets = {
            score_offset = 60,
            should_show_items = function(ctx)
              return ctx.trigger.initial_kind ~= "trigger_character"
            end,
          },
        },
      },
    },
  },
}
