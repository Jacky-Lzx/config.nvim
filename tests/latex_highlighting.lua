-- Run with the full configuration and installed plugins:
-- NVIM_SMOKE_TEST=1 nvim --headless -i NONE \
--   '+lua dofile("tests/latex_highlighting.lua")'
local lines = {
  "\\begin{equation}",
  "  \\label{eq:test}",
  "  &x = \\left( y + \\alpha \\right)",
  "\\end{equation}",
  "$x + \\alpha$",
  "\\includegraphics[width=0.8\\linewidth]{./Figures/design_space.pdf}",
}

local function flush_scheduled()
  local done = false
  vim.schedule(function()
    done = true
  end)
  assert(vim.wait(1000, function()
    return done
  end))
end

local function check_capture(row, col, expected)
  local captures = vim.inspect_pos(0, row, col).treesitter
  local math, token = false, false
  for _, capture in ipairs(captures) do
    assert(capture.capture ~= "markup.math", "upstream math capture is still active")
    local priority = tonumber(capture.metadata.priority) or 100
    if capture.capture == "markup.math.background" then
      assert(priority == 90)
      math = true
    elseif capture.capture == expected then
      assert(priority == 100)
      token = true
    end
  end
  assert(math and token, "missing captures at " .. row .. ":" .. col)
end

local function verify()
  assert(vim.bo.syntax == "")
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])
  vim.treesitter.get_parser(0, "latex"):parse()
  check_capture(0, 1, "module")
  check_capture(1, 3, "function.macro") -- \label
  check_capture(2, 2, "punctuation.delimiter") -- &
  check_capture(2, 7, "punctuation.delimiter") -- \left
  check_capture(2, 12, "punctuation.delimiter") -- (
  check_capture(4, 5, "function") -- inline math command

  local path_line = vim.api.nvim_buf_get_lines(0, 5, 6, false)[1]
  local open_col = assert(path_line:find("{", 1, true)) - 1
  local close_col = assert(path_line:find("}", 1, true)) - 1
  for _, col in ipairs({ open_col, close_col }) do
    local bracket_priority, path_priority = 0, 0
    for _, capture in ipairs(vim.inspect_pos(0, 5, col).treesitter) do
      local priority = tonumber(capture.metadata.priority) or 100
      if capture.capture == "punctuation.bracket" then
        bracket_priority = math.max(bracket_priority, priority)
      elseif capture.capture == "string.special.path" then
        path_priority = math.max(path_priority, priority)
      end
    end
    assert(
      path_priority > 0 and bracket_priority > path_priority,
      "path colors compete with braces during incremental highlighting"
    )
  end
  local path_color = false
  for _, capture in ipairs(vim.inspect_pos(0, 5, open_col + 2).treesitter) do
    assert(capture.capture ~= "punctuation.bracket", "bracket rule leaked into the path")
    path_color = path_color or capture.capture == "string.special.path"
  end
  assert(path_color, "file path highlighting was lost")

  -- Ephemeral conceal is tested by rendered screen text, not synconcealed().
  vim.wo.number, vim.wo.relativenumber = false, false
  vim.wo.signcolumn, vim.wo.foldcolumn, vim.wo.statuscolumn = "no", "0", ""
  vim.wo.foldenable, vim.wo.wrap = false, false
  vim.wo.conceallevel, vim.wo.concealcursor = 2, "nc"
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("normal! zt")
  vim.cmd.redraw({ bang = true })
  local origin = vim.fn.win_screenpos(0)
  local text = {}
  for col = origin[2], origin[2] + vim.api.nvim_win_get_width(0) - 1 do
    text[#text + 1] = vim.fn.screenstring(origin[1] + 2, col)
  end
  text = table.concat(text)
  assert(not text:find("left", 1, true) and not text:find("right", 1, true), "Math sizing was not concealed")
  assert(text:find("\\alpha", 1, true), "Math symbols must retain source spelling")
  assert(not vim.b.vimtex and vim.b.tex_tools_generation)
  local math = vim.api.nvim_get_hl(0, { name = "@markup.math", link = false })
  local background = vim.api.nvim_get_hl(0, { name = "@markup.math.background.latex", link = false })
  assert(math.fg and math.fg == background.fg, "math theme color was lost")
end

local ok, err = pcall(function()
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = "tex"
  flush_scheduled()
  verify()

  for _ = 1, 3 do
    vim.api.nvim_buf_set_lines(0, 1, 2, false, { "  \\label{eq:edited}" })
    verify()
    vim.api.nvim_buf_set_lines(0, 1, 2, false, { lines[2] })
    verify()
    vim.api.nvim_buf_set_lines(0, 5, 6, false, {
      "\\includegraphics[width=0.8\\linewidth]{./Figures/edited.pdf}",
    })
    verify()
    vim.api.nvim_buf_set_lines(0, 5, 6, false, { lines[6] })
    verify()
  end

  vim.cmd.colorscheme("catppuccin-nvim")
  flush_scheduled()
  verify()
  vim.cmd("syntax enable")
  vim.bo.syntax = "tex"
  flush_scheduled()
  verify()

  vim.cmd("enew!")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = "tex"
  flush_scheduled()
  verify()
end)

if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
else
  print("PASS: Tree-sitter priorities and tex-tools conceal survive edits, theme/syntax reloads and new buffers")
  vim.cmd("qa!")
end
