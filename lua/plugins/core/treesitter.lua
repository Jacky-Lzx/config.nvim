-- NOTE: Since the tree-sitter repo is archieved, there is a nother repo "romus204/tree-sitter-manager.nvim" to do the
--         job related to highlighting <2026.05.12, lzx>

return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    specs = {
      -- This tool is used for the compilation of some tree-sitter parsers, e.g. LaTeX
      -- NOTE: tree-sitter-cli 0.26.0 is a breaking change, the tree-sitter-cli is better manually installed in the system. <2026.04.30, lzx>
      -- {
      --   "mason-org/mason.nvim",
      --   optional = true,
      --   opts_extend = { "ensure_installed" },
      --   opts = { ensure_installed = { "tree-sitter-cli" } },
      -- },
    },
    opts = {
      ensure_installed = { "regex" },
    },
    config = function(_, opts)
      local ts = require("nvim-treesitter")
      local ensure_installed = opts.ensure_installed
      opts.ensure_installed = nil

      ts.setup(opts)

      vim.schedule(function()
        ts.install(ensure_installed)
      end)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("lzx_treesitter", { clear = true }),
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    end,
  },
}
