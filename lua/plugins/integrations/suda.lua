--- An alternative sudo.vim for Vim and Neovim, limited support sudo in Windows
--- Usage:
---   :SudaRead -- Re-open a current file with sudo
---   :SudaWrite -- Forcedly save a current file with sudo

return {
  {
    "lambdalisue/vim-suda",
    cmd = { "SudaWrite", "SudaRead" },
  },
}
