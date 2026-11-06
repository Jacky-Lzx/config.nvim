return {
  {
    id = "toolchain-tools.nvim",
    opts = {
      parsers = {
        sources = {
          latex = {
            parser = {
              url = "https://github.com/Jacky-Lzx/tree-sitter-latex",
              revision = "921e4a5d8903e50735e8f613d85586f44e857b01",
              generate = true,
            },
          },
        },
      },
    },
  },
  {
    config = function(ctx)
      vim.g.tex_flavor = "latex"
      -- tex-tools owns conceal; native TeX syntax must not add replacements.
      vim.g.tex_conceal = ""
      require("tex-tools").setup(ctx.opts)
    end,
    id = "tex-tools.nvim",
    source = "Jacky-Lzx/tex-tools.nvim",
    dev = true,
    main = "tex-tools",
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
      -- mappings = false, -- languages.latex.buffer owns the existing key layout.
      mappings = true,
      smart_enter = false, -- Blink -> pairs.nvim owns Insert-mode Enter.
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
  {
    id = "texpresso.vim",
    source = "let-def/texpresso.vim",
    enabled = false, -- Requires texpresso when enabled.
  },
}
