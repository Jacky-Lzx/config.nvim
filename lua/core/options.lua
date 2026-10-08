local M = {}

function M.setup()
  local options = {
    number = true,
    termguicolors = true,
    signcolumn = "yes:1",
    winborder = "rounded",
    wrap = false,
    linebreak = true,
    scrolloff = 5,
    sidescrolloff = 8,
    startofline = false,
    splitbelow = true,
    splitright = true,
    splitkeep = "screen",
    ignorecase = true,
    smartcase = true,
    incsearch = true,
    hlsearch = true,
    expandtab = true,
    tabstop = 2,
    softtabstop = -1,
    shiftwidth = 2,
    shiftround = true,
    textwidth = 0,
    wrapmargin = 0,
    list = true,
    listchars = "tab:>-,trail:·,nbsp:␣",
    mouse = "a",
    mousetime = 0,
    clipboard = "",
    autoread = true,
    undofile = true,
    confirm = true,
  }

  for name, value in pairs(options) do
    vim.o[name] = value
  end

  vim.g.markdown_recommended_style = 0
  if not vim.g.colors_name then
    vim.cmd.colorscheme("habamax")
  end
end

return M
