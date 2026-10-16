return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    -- The shared Nix module supplies tree-sitter-cli; parser installation is explicit.
    opts = {
      ensure_installed = vim.list_extend({ "regex" }, require("languages").current().parsers),
    },
    config = function(_, opts)
      local ts = require("nvim-treesitter")
      local ensure_installed = opts.ensure_installed
      local setup_opts = vim.deepcopy(opts)
      setup_opts.ensure_installed = nil

      ts.setup(setup_opts)

      vim.api.nvim_create_user_command("TSInstallConfigured", function()
        ts.install(ensure_installed)
      end, { desc = "Install Tree-sitter parsers for enabled language profiles", force = true })

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
