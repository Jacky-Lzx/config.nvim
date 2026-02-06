-- Automatically start treesitter for supported filetypes
-- Reference materials:
-- - https://github.com/nvim-treesitter/nvim-treesitter/issues/8308
-- - https://github.com/lewis6991/ts-install.nvim/issues/9
-- - https://github.com/nvim-treesitter/nvim-treesitter/discussions/7927
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match) or args.match
    local installed = require("nvim-treesitter").get_installed("parsers")
    if vim.tbl_contains(installed, lang) then
      vim.treesitter.start(args.buf)
    end
  end,
})

return {
  -- 2026.02.06: This plugin is updated from the master branch to main branch.
  -- Some options are invalid anymore (all opts presented here)
  -- The auto install function is fixed referring to the mason plugin
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    opts = {
      -- auto_install = true,
      -- highlight = {
      --   enable = true,
      --   -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      --   -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      --   -- Using this option may slow down your editor, and you may see some duplicate highlights.
      --   -- Instead of true it can also be a list of languages
      --   additional_vim_regex_highlighting = false,
      -- },
      ensure_installed = { "regex" },
      -- indent = {
      --   enabale = true,
      -- },
    },
    config = function(_, opts)
      local ts = require("nvim-treesitter")

      ts.setup(opts)

      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          ts.install(tool)
        end
      end

      ensure_installed()
    end,
  },

  -- This tool is used for the compilation of some tree-sitter parsers, e.g. LaTeX
  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "tree-sitter-cli" } },
  },
}
