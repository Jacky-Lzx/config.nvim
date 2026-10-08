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
  local map = vim.keymap.set

  map("i", "jk", "<Esc>", { desc = "Leave Insert mode" })
  for key, direction in pairs({ h = "Left", j = "Down", k = "Up", l = "Right" }) do
    map("i", "<C-" .. key .. ">", "<" .. direction .. ">", { desc = "Move " .. direction:lower() })
    map("n", "<C-" .. key .. ">", "<C-w>" .. key, { desc = "Focus window " .. direction:lower() })
  end

  map({ "n", "x", "o" }, "H", "^", { desc = "First nonblank character" })
  map({ "n", "x", "o" }, "L", "$", { desc = "End of line" })
  map("x", "<", "<gv", { desc = "Indent left and retain selection" })
  map("x", ">", ">gv", { desc = "Indent right and retain selection" })

  map({ "n", "x" }, "Q", "<Cmd>qa<CR>", { desc = "Quit Neovim" })
  map({ "n", "x" }, "qq", "<Cmd>quit<CR>", { desc = "Close window" })
  map("n", "<leader>J", "<Cmd>cnext<CR>", { desc = "Next quickfix entry" })
  map("n", "<leader>K", "<Cmd>cprevious<CR>", { desc = "Previous quickfix entry" })
  map("n", "<A-z>", "<Cmd>setlocal wrap!<CR>", { desc = "Toggle line wrap" })

  -- Only a bare Visual :write loses its range; substitutions and exports retain it.
  map("c", "<CR>", command_enter, { expr = true, desc = "Confirm command; save full buffer with Visual :write" })
end

return M
