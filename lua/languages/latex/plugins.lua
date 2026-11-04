local platform = require("utils.platform")

return {
  {
    "toolchain-tools.nvim",
    optional = true,
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
    "Jacky-Lzx/tex-tools.nvim",
    dev = true,
    main = "tex-tools",
    -- Formula display requires image-tools only after a preview is ready.
    ft = { "tex", "plaintex" },
    init = function()
      vim.g.tex_flavor = "latex"
      -- tex-tools owns conceal; native TeX syntax must not add replacements.
      vim.g.tex_conceal = ""
    end,
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
    "let-def/texpresso.vim",
    enabled = platform.executable("texpresso") ~= nil,
    ft = { "tex" },
  },
}
