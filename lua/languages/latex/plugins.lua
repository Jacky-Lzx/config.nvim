local latex_source = {
  url = "https://github.com/Jacky-Lzx/tree-sitter-latex",
  revision = "e1cad6c26868e986911e364cc2655fd4ec81bdf7",
}

return {
  {
    id = "toolchain-tools.nvim",
    opts = {
      parsers = {
        sources = {
          latex = {
            parser = vim.tbl_extend("force", latex_source, {
              generate = true,
              queries = "neovim/queries/latex",
            }),
            query_source = latex_source,
            query_path = "neovim/queries/latex",
          },
        },
      },
    },
  },
  {
    config = function(ctx)
      require("tex-tools").setup(ctx.opts)
    end,
    id = "tex-tools.nvim",
    source = "Jacky-Lzx/tex-tools.nvim",
    version = "main",
    dev = true,
    main = "tex-tools",
    mount = "on-demand",
    ft = { "tex", "plaintex" },
    -- Formula display requires image-tools only after a preview is ready.
    opts = {
      lsp = "texquill",
      formula_preview = { enabled = true },
      viewer = {
        method = "pagewing",
        -- Use the macOS app bundle so menu bars can resolve its app identity and icon.
        executable = "/Applications/Pagewing.app/Contents/MacOS/pagewing",
        focus = false,
      },
      mappings = false, -- languages.latex.buffer owns the key layout.
      smart_enter = false, -- completion-tools and pairs.nvim own Insert-mode Enter.
      conceal = { math_symbols = false, spacing = false },
      build = {
        profiles = {
          tectonic = {
            executable = "tectonic",
          },
          latexmk = {
            executable = "latexmk",
          },
          xelatex = {
            executable = "latexmk",
            engine = "xelatex",
          },
        },
      },
    },
  },
}
