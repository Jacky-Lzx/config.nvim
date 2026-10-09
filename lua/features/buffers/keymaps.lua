local M = {}

function M.get()
  local keys = {
    { "<A-S-,>", "<Cmd>BufferMovePrevious<CR>", desc = "[Buffer] Move buffer left" },
    { "<A-S-.>", "<Cmd>BufferMoveNext<CR>", desc = "[Buffer] Move buffer right" },
    { "<A-<>", "<Cmd>BufferMovePrevious<CR>", desc = "[Buffer] Move buffer left" },
    { "<A->>", "<Cmd>BufferMoveNext<CR>", desc = "[Buffer] Move buffer right" },
    { "<A-h>", "<Cmd>BufferPrevious<CR>", desc = "[Buffer] Previous buffer" },
    { "<A-l>", "<Cmd>BufferNext<CR>", desc = "[Buffer] Next buffer" },
    { "[b", "<Cmd>BufferPrevious<CR>", desc = "[Buffer] Previous buffer" },
    { "]b", "<Cmd>BufferNext<CR>", desc = "[Buffer] Next buffer" },
    { "<A-w>", "<Cmd>BufferClose<CR>", desc = "Close buffer" },
    { "<A-u>", "<Cmd>BufferRestore<CR>", desc = "Restore buffer" },
  }
  for index = 1, 9 do
    keys[#keys + 1] =
      { "<A-" .. index .. ">", "<Cmd>BufferGoto " .. index .. "<CR>", desc = "[Buffer] Go to buffer " .. index }
  end
  return keys
end

return M
