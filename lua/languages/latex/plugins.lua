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
    "lervag/vimtex",
    lazy = true, -- lazy-loading will disable inverse search
    ft = { "tex", "latex", "bib" },
    init = function()
      vim.g.tex_flavor = "latex"
      -- Viewer options: One may configure the viewer either by specifying a built-in viewer method:
      vim.g.vimtex_view_enabled = platform.skim_displayline() ~= nil or platform.executable("zathura") ~= nil

      -- Removed default imap
      vim.g.vimtex_imaps_enabled = false

      -- Silence the compiler messages during start, stop, and callbacks
      -- vim.g.vimtex_compiler_silent = true

      vim.g.vimtex_complete_enabled = false
      vim.g.vimtex_syntax_enabled = true -- This config controls conceals. Should be true
      vim.g.vimtex_indent_enabled = false

      vim.g.vimtex_quickfix_enabled = true
      -- Only open quickfix when there are errors, not warnings
      vim.g.vimtex_quickfix_open_on_warning = false
      vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
      vim.g.vimtex_quickfix_mode = 0

      -- vim.g.vimtex_view_method = "zathura_simple"
      -- vim.g.vimtex_view_zathura_use_synctex = 0

      if platform.skim_displayline() then
        vim.g.vimtex_view_method = "skim"
        vim.g.vimtex_view_skim_sync = 1
      elseif platform.executable("zathura") then
        vim.g.vimtex_view_method = "zathura_simple"
      end

      -- VimTeX uses latexmk as the default compiler backend. If you use it, which is strongly recommended, you probably
      -- don't need to configure anything. If you want another compiler backend, you can change it as follows. The list
      -- of supported backends and further explanation is provided in the documentation, see ":help vimtex-compiler".
      vim.g.vimtex_compiler_method = "latexmk"

      vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover

      vim.g.vimtex_syntax_conceal = {
        accents = 1,
        ligatures = 1,
        cites = 1,
        fancy = 1,
        spacing = 1,
        greek = 0,
        math_bounds = 1,
        math_delimiters = 1,
        math_fracs = 0,
        math_super_sub = 0,
        math_symbols = 0,
        sections = 0,
        styles = 1,
      }

      vim.g.vimtex_fold_enabled = 1
    end,
  },
  {
    "f3fora/nvim-texlabconfig",
    enabled = platform.executable("go") ~= nil,
    build = "go build",
    ft = { "tex", "bib" }, -- Lazy-load on filetype

    opts = {},
    config = function(_, opts)
      require("texlabconfig").setup(opts)
    end,
  },
  {
    "let-def/texpresso.vim",
    enabled = platform.executable("texpresso") ~= nil,
    ft = { "tex" },
  },
}
