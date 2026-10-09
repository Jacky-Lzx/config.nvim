local M = {}

function M.setup()
  local options = {
    termguicolors = true,

    number = true,
    ignorecase = true,
    smartcase = true,
    hlsearch = true,
    incsearch = true,

    -- Disable multi-click recognition while preserving single-click positioning and drag selection.
    mousetime = 0,

    tabstop = 2,
    softtabstop = -1,
    shiftwidth = 2,
    shiftround = true,
    expandtab = true,
    smartindent = true,

    scrolloff = 5,
    sidescrolloff = 8,
    startofline = false,

    list = true,
    listchars = "tab:>-,trail:·,nbsp:␣",

    conceallevel = 2,

    splitbelow = true,
    splitright = true,
    splitkeep = "screen",

    wrap = false,
    linebreak = true,

    winborder = "rounded",

    cursorline = false,

    -- TODO: What is this? <2026.10.09, lzx>
    clipboard = "",

    textwidth = 0,

    signcolumn = "yes:1",

    autoread = true,
    undofile = true,
    confirm = true,
  }

  for name, value in pairs(options) do
    vim.o[name] = value
  end

  -- Do not show `~` when the buffer is end
  -- See `https://github.com/catppuccin/nvim/commit/50c34a2cf18776a77f770fcf5df777de6fe69e08`
  vim.opt.fillchars:append({ eob = " " })
  -- Do not show strikethroughs in the diff view
  vim.opt.fillchars:append({ diff = " " })

  local platform = require("utils.platform")
  local shell = platform.shell()
  if shell then
    vim.opt.shell = shell
  end

  local python_host = platform.python_host()
  if python_host then
    vim.g.python3_host_prog = python_host
  end

  -- TODO: Find a better place to config this <2026.10.09, lzx>
  vim.g.markdown_recommended_style = 0
  vim.g.no_python_maps = true
  vim.g.no_rust_maps = true
end

return M
