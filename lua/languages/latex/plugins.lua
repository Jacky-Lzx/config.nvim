local platform = require("utils.platform")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    init = function()
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("lzx_treesitter_latex", { clear = true }),
        pattern = "TSUpdate",
        callback = function()
          require("nvim-treesitter.parsers").latex.install_info = {
            url = "https://github.com/Jacky-Lzx/tree-sitter-latex",
            branch = "master",
            generate = true,
          }
        end,
      })
    end,
  },
  {
    "Jacky-Lzx/tex-tools.nvim",
    dev = true,
    main = "tex-tools",
    ft = { "tex", "plaintex" },
    init = function()
      vim.g.tex_flavor = "latex"
      -- tex-tools owns conceal; native TeX syntax must not add replacements.
      vim.g.tex_conceal = ""
    end,
    opts = {
      mappings = false, -- languages.latex.buffer owns the existing key layout.
      smart_enter = false, -- Blink -> pairs.nvim owns Insert-mode Enter.
      conceal = { math_symbols = false },
      build = {
        profiles = {
          tectonic = {
            executable = "tectonic",
            args = { "-X", "compile", "%f", "--synctex", "--keep-logs", "--keep-intermediates" },
          },
          latexmk = {
            executable = "latexmk",
            args = { "-pdf", "-synctex=1", "-interaction=nonstopmode", "-file-line-error", "%f" },
          },
          xelatex = {
            executable = "latexmk",
            args = { "-xelatex", "-synctex=1", "-interaction=nonstopmode", "-file-line-error", "%f" },
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
