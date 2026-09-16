-- Run with the full configuration and installed plugins:
-- NVIM_SMOKE_TEST=1 nvim --headless -i NONE \
--   '+lua dofile("tests/latex_highlighting.lua")'
local lines = {
  "\\begin{equation}",
  "  \\label{eq:test}",
  "  &x = \\left( y + \\alpha \\right)",
  "\\end{equation}",
  "$x + \\alpha$",
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
  assert(vim.bo.syntax == "tex")
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])
  vim.treesitter.get_parser(0, "latex"):parse()
  check_capture(0, 1, "module")
  check_capture(1, 3, "function.macro") -- \label
  check_capture(2, 2, "punctuation.delimiter") -- &
  check_capture(2, 7, "punctuation.delimiter") -- \left
  check_capture(2, 12, "punctuation.delimiter") -- (
  check_capture(4, 5, "function") -- inline math command

  local conceal = vim.fn.synconcealed(3, 8)
  assert(conceal[1] == 1 and conceal[2] == "(", "VimTeX conceal was lost")
  for name, attrs in pairs(vim.api.nvim_get_hl(0, {})) do
    if name:match("^tex[A-Z]") then
      assert(vim.tbl_isempty(attrs), "VimTeX style restored: " .. name)
    end
  end
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
  print("PASS: Tree-sitter priorities and VimTeX conceal survive edits, theme/syntax reloads and new buffers")
  vim.cmd("qa!")
end
