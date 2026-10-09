return {
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = {
      {
        "Kaiser-Yang/blink-cmp-dictionary",
        dependencies = { "nvim-lua/plenary.nvim" },
      },
    },
    opts = {
      sources = {
        -- Add 'dictionary' to the list
        default = { "dictionary" },
        providers = {
          dictionary = {
            score_offset = 5,
            module = "blink-cmp-dictionary",
            name = "Dict",
            -- Make sure this is at least 2.
            -- 3 is recommended
            min_keyword_length = 3,
            max_items = 10,
            opts = {
              -- options for blink-cmp-dictionary
              dictionary_files = { require("utils.paths").config("configs", "dictionary.txt") },
            },
          },
        },
      },
    },
  },
}
