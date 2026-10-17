return {
  {
    "saghen/blink.cmp",
    optional = true,
    specs = { { "ribru17/blink-cmp-spell", lazy = true } },
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
