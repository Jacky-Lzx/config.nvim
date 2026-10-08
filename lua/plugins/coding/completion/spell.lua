return {
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "ribru17/blink-cmp-spell" },
    opts = {
      sources = {
        default = { "spell" },
        providers = {
          -- ...
          spell = {
            name = "Spell",
            module = "blink-cmp-spell",
            score_offset = 10,
            opts = {
              use_cmp_spell_sorting = true,
            },
          },
        },
      },
    },
  },
}
