return {
  {
    id = "typst-preview.nvim",
    enabled = false,
    source = "chomosuke/typst-preview.nvim",
    main = "typst-preview",
    -- Configure without setup()'s eager binary downloader. Native plugin
    -- scripts register commands; :TypstPreviewUpdate remains an explicit action.
    config = function(ctx)
      require("typst-preview.config").config(ctx.opts)
    end,
    opts = {
      -- Use tinymist installed by toolchain
      dependencies_bin = {
        ["tinymist"] = "tinymist",
      },
    },
  },
}
