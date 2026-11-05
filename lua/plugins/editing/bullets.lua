return {
  {
    id = "bullets.vim",
    source = "bullets-vim/bullets.vim",
    enabled = false,
    config = function()
      vim.g.bullets_set_mappings = 0 -- disable adding default key mappings, default = 1
      vim.g.bullets_custom_mappings = {
        { "imap", "<cr>", "<Plug>(bullets-newline)" },
      }
    end,
  },
}
