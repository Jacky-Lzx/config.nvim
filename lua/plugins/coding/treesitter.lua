return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    -- The shared Nix module supplies tree-sitter-cli; parser installation is explicit.
    opts = {},
    config = function(_, opts)
      local ts = require("nvim-treesitter")
      ts.setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("lzx_treesitter", { clear = true }),
        callback = function(ev)
          -- LaTeX highlighting is configured in after/ftplugin/tex.lua.
          if ev.match == "tex" then
            return
          end

          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    end,
  },
}
