return {
  {
    "bullets-vim/bullets.vim",
    cond = false,
    ft = { "markdown", "text", "gitcommit" },

    config = function()
      vim.g.bullets_set_mappings = 0 -- disable adding default key mappings, default = 1
      vim.g.bullets_custom_mappings = {
        { "imap", "<cr>", "<Plug>(bullets-newline)" },
      }
    end,
  },
}
