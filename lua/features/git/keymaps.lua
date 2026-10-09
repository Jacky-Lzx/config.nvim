local M = {}

function M.attach(bufnr)
  local gs = require("gitsigns")
  local function map(mode, key, action, description)
    vim.keymap.set(mode, key, action, { buffer = bufnr, desc = "[Git] " .. description })
  end
  for key, direction in pairs({ ["]h"] = "next", ["]H"] = "last", ["[h"] = "prev", ["[H"] = "first" }) do
    map("n", key, function()
      if vim.wo.diff then
        vim.cmd.normal({ key, bang = true })
      else
        gs.nav_hunk(direction)
      end
    end, direction .. " hunk")
  end
  map("n", "<leader>ggs", gs.stage_hunk, "Stage hunk")
  map("n", "<leader>ggr", gs.reset_hunk, "Reset hunk")
  map("x", "<leader>ggs", function()
    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, "Stage selected lines")
  map("x", "<leader>ggr", function()
    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, "Reset selected lines")
  map("n", "<leader>ggS", gs.stage_buffer, "Stage buffer")
  map("n", "<leader>ggR", gs.reset_buffer, "Reset buffer")
  map("n", "<leader>ggp", gs.preview_hunk, "Preview hunk")
  map("n", "<leader>ggP", gs.preview_hunk_inline, "Preview hunk inline")
  map("n", "<leader>ggd", gs.diffthis, "Diff against index")
  map("n", "<leader>ggD", function()
    gs.diffthis("~")
  end, "Diff against previous commit")
  map("n", "<leader>ggq", gs.setqflist, "Buffer hunks to quickfix")
  map("n", "<leader>ggQ", function()
    gs.setqflist("all")
  end, "Repository hunks to quickfix")
  map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
  map("n", "<leader>tgb", gs.toggle_current_line_blame, "Toggle line blame")
  map("n", "<leader>tgw", gs.toggle_word_diff, "Toggle word diff")
  map("n", "<leader>tgs", gs.toggle_signs, "Toggle Git signs")
end

return M
