vim.g.tex_flavor = "latex"

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "tex",
--   callback = function(args)
--     vim.treesitter.stop(args.buf)
--   end,
-- })

vim.lsp.config("texlab", {
  settings = {
    texlab = {
      -- build = {
      --   executable = "latexmk",
      --   args = {
      --     "%f",
      --   },
      --   onSave = false,
      --   forwardSearchAfter = false,
      -- },
      build = {
        executable = "tectonic",
        args = {
          "-X",
          "compile",
          "%f",
          "--synctex",
          "--keep-logs",
          "--keep-intermediates",
        },
        onSave = false,
        forwardSearchAfter = false,
      },
      -- Use Skim for preview and forward search
      -- The inverse search is configured in "f2fora/nvim-texlabconfig"
      forwardSearch = {
        executable = "/Applications/Skim.app/Contents/SharedSupport/displayline",
        args = { "-r", "%l", "%p", "%f" },
      },
      chktex = {
        onOpenAndSave = false,
        onEdit = false,
        additionalArgs = {
          "-wall",
          "-q",
          "-n1",
          "-n3",
          "-n8",
          "-n9",
          "-n22",
          "-n30",
          "-n24",
          "-n17",
          "-e16",
        },
      },
      bibtexFormatter = "texlab", -- @type "texlab" | "latexindent" | "none"; @default "texlab"
      latexFormatter = "none", -- @type "texlab" | "latexindent" | "none"; @default "latexindent"
      -- latexindent = {
      -- ["local"] = "~/.config/latexindent/lzx_settings.yaml", -- local is a reserved keyword
      -- ["local"] = vim.env.HOME .. "/.config/latexindent/lzx_settings.yaml", -- local is a reserved keyword
      -- modifyLineBreaks = true, -- @default false
      -- },
    },
  },
})
-- NOTE: Currently TeXLab does not work correctly in terms of formatting
vim.lsp.enable("texlab")

vim.keymap.set("n", "<leader>lb", "<CMD>LspTexlabBuild<CR>", { desc = "[Texlab] Build LaTeX" })

local M = {
  -- Add BibTeX/LaTeX to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts_extend = { "ensure_installed", "highlight.disable" },
    opts = {
      -- A temporary workaround to avoid the building issue of latex parser.
      -- See `https://github.com/nvim-treesitter/nvim-treesitter/issues/7781#issuecomment-3816426774`
      ensure_installed = { "latex", "bibtex" },
      -- ensure_installed = { "bibtex" },
      highlight = {
        disable = { "latex" },
      },
    },
    -- opts = function(_, opts)
    --   opts.ensure_installed = opts.ensure_installed or {}
    --   vim.list_extend(opts.ensure_installed, { "latex", "bibtex" })
    --
    --   opts.highlight = opts.highlight or {}
    --   opts.highlight.disable = opts.highlight.disable or {}
    --   opts.highlight.disable = { "latex" }
    -- end,
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "tex-fmt" } },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        tex = { "tex-fmt" },
        -- tex = { "latexindent" },
        -- The tex-fmt for bib cannot align the entries, or add additional spaces around `=`
        -- bib = { "tex-fmt" },
      },
      formatters = {
        ["tex-fmt"] = {
          prepend_args = { "-l", "120" },
        },
        latexindent = {
          prepend_args = { "--local", vim.fn.stdpath("config") .. "/configs/latexindent.yaml" },
        },
      },
    },
  },

  -- linter
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft = vim.tbl_extend("force", opts.linters_by_ft, { tex = { "chktex" } })

      local chktex_l = require("lint").linters.chktex
      -- stylua: ignore
      chktex_l.args = {
        "-wall", "-q", "-n1", "-n3", "-n8", "-n9", "-n22", "-n30", "-n24", "-n17", "-e16",
        "-v0", "-I0", "-s", ":", "-f", "%l%b%c%b%d%b%k%b%n%b%m%b%b%b",
      }
      chktex_l.ignore_exitcode = true
    end,
  },

  {
    "lervag/vimtex",
    -- lazy = false, -- lazy-loading will disable inverse search
    ft = { "tex", "bib" },
    dependencies = {
      {
        "folke/which-key.nvim",
        optional = true,
        opts = {
          spec = {
            { "<leader>l", group = "[VimTeX]" },
          },
        },
      },
    },

    config = function()
      -- Viewer options: One may configure the viewer either by specifying a built-in viewer method:
      vim.g.vimtex_view_enabled = true

      -- vim.g.vimtex_view_method = "zathura_simple"
      -- vim.g.vimtex_view_zathura_use_synctex = 0

      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_view_skim_sync = 1

      -- VimTeX uses latexmk as the default compiler backend. If you use it, which is strongly recommended, you probably
      -- don't need to configure anything. If you want another compiler backend, you can change it as follows. The list
      -- of supported backends and further explanation is provided in the documentation, see ":help vimtex-compiler".
      vim.g.vimtex_compiler_method = "latexmk"

      vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
      vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"

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

  -- Texlab is a popular Language Server for LaTeX, which supports Forward Search and Inverse Search between TeX and PDF
  -- files. nvim-texlabconfig provides some useful snippets to configure this capability for neovim and some viewers and
  -- a homonymous executable which allows a fast Inverse Search. Should setup pdf viewer as well, see the documentation
  {
    "f3fora/nvim-texlabconfig",
    -- build = "go build",
    build = "go build -o ~/.local/bin/", -- if e.g. ~/.local/bin/ is in $PATH
    ft = { "tex", "bib" }, -- Lazy-load on filetype

    opts = {},
    config = function(_, opts)
      require("texlabconfig").setup(opts)
    end,
  },

  -- To enable auto-rendering of pdf files, you should follow the instructions in https://github.com/let-def/texpresso,
  -- and make sure the texpresso executable is in your $PATH.
  {
    "let-def/texpresso.vim",
    ft = { "tex" },
  },
}

return M
