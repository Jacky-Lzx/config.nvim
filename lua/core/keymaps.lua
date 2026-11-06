local M = {}

local function command_enter()
  if vim.fn.getcmdtype() == ":" then
    local command = vim.fn.getcmdline():match("^'<,'>%s*(.-)%s*$")
    local whole_buffer_write = { w = true, ["w!"] = true, write = true, ["write!"] = true }
    if whole_buffer_write[command] then
      return "<C-e><C-u>" .. command .. "<CR>"
    end
  end
  return "<CR>"
end

function M.setup()
  local del = vim.keymap.del
  local map = vim.keymap.set

  del("n", "]a")
  del("n", "]A")
  del("n", "[a")
  del("n", "[A")

  map("i", "jk", "<Esc>", { desc = "Leave Insert mode" })

  for key, direction in pairs({ h = "Left", j = "Down", k = "Up", l = "Right" }) do
    map("i", "<C-" .. key .. ">", "<" .. direction .. ">", { desc = "Move " .. direction:lower() })
    map("n", "<C-" .. key .. ">", "<C-w>" .. key, { desc = "Focus window " .. direction:lower() })
  end

  map({ "n", "x", "o" }, "H", "^", { desc = "First nonblank character" })
  map({ "n", "x", "o" }, "L", "$", { desc = "End of line" })

  -- Better indenting (Re-select the texts after indentation)
  map("x", "<", "<gv", { desc = "Indent left and retain selection" })
  map("x", ">", ">gv", { desc = "Indent right and retain selection" })

  map("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment line" })
  map("x", "<leader>/", "gc", { remap = true, desc = "Toggle comments in selection" })

  map("n", "zS", function()
    if vim.v.count == 0 then
      vim.notify("Use a count to set foldlevel, e.g. 2zS; zM closes all folds", vim.log.levels.WARN)
      return
    end
    vim.wo.foldlevel = vim.v.count
  end, { desc = "Set foldlevel" })
  map("n", "zK", function()
    require("ui_tools.fold").preview()
  end, { desc = "Preview closed fold; repeat to focus" })

  map({ "n", "x" }, "Q", "<Cmd>qa<CR>", { desc = "Quit Neovim" })
  map({ "n", "x" }, "qq", "<Cmd>quit<CR>", { desc = "Close window" })

  map("n", "<leader>J", "<Cmd>cnext<CR>", { desc = "Next quickfix entry" })
  map("n", "<leader>K", "<Cmd>cprevious<CR>", { desc = "Previous quickfix entry" })
  map("n", "<A-z>", "<Cmd>setlocal wrap!<CR>", { desc = "Toggle line wrap" })
  map("n", "//", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>", {
    desc = "Clear search highlighting and redraw",
    silent = true,
  })

  -- Only a bare Visual :write loses its range; substitutions and exports retain it.
  map("c", "<CR>", command_enter, { expr = true, desc = "Confirm command; save full buffer with Visual :write" })

  map("x", "go", function()
    require("file_tools").open_at_cursor()
  end, { desc = "Open selected path or URL", nowait = true })
  map("n", "go", function()
    local lsp = package.loaded["vim.lsp"]
    if lsp and #lsp.get_clients({ bufnr = 0, method = "textDocument/documentLink" }) > 0 then
      require("lsp-tools").open_link()
    else
      require("file_tools").open_at_cursor()
    end
  end, { desc = "Open semantic link or path", nowait = true })
end

return M
