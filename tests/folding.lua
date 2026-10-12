local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/runtime")
require("config.context").initialize({ profiles = {}, features = {} })
-- nvim-treesitter normally registers this filetype alias at startup.
vim.treesitter.language.register("latex", "tex")
vim.cmd("filetype plugin on")
vim.o.shiftwidth = 2
local before = #vim.api.nvim_get_autocmds({})
local native_k = vim.fn.maparg("K", "n", false, true)
local folding = require("features.folding")
assert(#vim.api.nvim_get_autocmds({}) == before, "Requiring folding must be pure")
folding.setup()

local function normal(keys)
  vim.cmd("normal! " .. keys)
end

local function fixture(ft, lines)
  vim.cmd("enew!")
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = ft
  assert(
    vim.wait(2000, function()
      return vim.wo[win].foldlevel ~= 99
    end),
    "Fold level initialization timed out: " .. ft
  )
  return buf, win
end

local buf, win = fixture("lua", {
  "local function outer()",
  "  if true then",
  "    print('你好')",
  "    print('two')",
  "  end",
  "end",
  "return outer",
})
assert(vim.wo.foldmethod == "expr", "Lua must use native Tree-sitter folds")
assert(vim.fn.foldlevel(3) >= 2, "Missing nested Tree-sitter folds")
local depth = vim.wo.foldlevel
normal("zm")
assert(vim.wo.foldlevel == depth - 1 and vim.fn.foldclosed(2) == 2, "First zm must close inner folds")
normal("zM")

vim.treesitter.start(buf)
local text = vim.fn.foldtextresult(1)
assert(text == "local function outer()  󰁂 5", "Fold count must follow text with exactly two spaces")
local colors
local original_text = folding.text
folding.text = function()
  colors = original_text()
  return colors
end
vim.fn.foldtextresult(1)
folding.text = original_text
assert(
  vim.iter(colors):any(function(chunk)
    return chunk[2]:match("^@")
  end),
  "Folded line lost TS highlights"
)

local preview_buf, preview_win = folding.preview()
assert(vim.api.nvim_get_current_win() == win, "Preview stole focus")
assert(vim.bo[preview_buf].buftype == "nofile" and not vim.bo[preview_buf].modifiable)
assert(vim.api.nvim_buf_get_lines(preview_buf, 0, -1, false)[3] == "    print('你好')")
assert(vim.api.nvim_win_get_height(preview_win) <= 20 and vim.api.nvim_win_get_width(preview_win) <= 100)
folding.preview()
assert(vim.api.nvim_get_current_win() == preview_win, "Second preview must focus the float")
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "xt", false)
assert(not vim.api.nvim_win_is_valid(preview_win), "Escape did not close preview")
vim.api.nvim_set_current_win(win)
normal("zR")
assert(folding.preview() == nil, "Open folds must not spawn a preview")
normal("zM")
local _, moving_preview = folding.preview()
vim.wait(30)
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = buf })
assert(
  vim.wait(500, function()
    return not vim.api.nvim_win_is_valid(moving_preview)
  end),
  "Moving the cursor did not close preview"
)
assert(vim.fn.foldclosed(3) == 1)
normal("zR")
assert(vim.fn.foldclosed(3) == -1 and vim.wo.foldlevel == depth)
normal("2zm")
assert(vim.wo.foldlevel == math.max(depth - 2, 0))
normal("2zr")
assert(vim.wo.foldlevel == depth)
normal("zM")

-- Other windows and revisiting the buffer must not reopen the existing window.
vim.cmd("vsplit")
local other = vim.api.nvim_get_current_win()
assert(vim.wait(2000, function()
  return vim.wo[other].foldlevel ~= 99
end))
normal("zR")
vim.api.nvim_set_current_win(win)
assert(vim.wo.foldlevel == 0 and vim.fn.foldclosed(3) == 1, "WinEnter reset existing folds")
vim.api.nvim_set_current_win(other)
fixture("unknown_folding_test", { "outer", "  inner", "    body", "    body", "  last", "end" })
assert(vim.wo.foldmethod == "indent", "Missing parser must fall back to indent")
vim.api.nvim_set_current_buf(buf)
vim.wait(50)
assert(vim.wo.foldmethod == "expr", "Returning to Lua lost Tree-sitter folding")
vim.api.nvim_set_current_win(win)
assert(vim.wo.foldlevel == 0)

-- Existing computed folds update after edits and native zx/zX remain available.
vim.api.nvim_buf_set_lines(buf, 4, 4, false, { "    print('inserted')" })
assert(
  vim.wait(2000, function()
    return vim.fn.foldclosedend(1) == 7
  end),
  "Edited fold range stayed stale"
)
normal("zx")
normal("zX")
normal("zR")
assert(vim.fn.foldlevel(3) >= 2)

for _, case in ipairs({
  { "python", { "def outer():", "    if True:", "        print(1)", "        print(2)", "    return 0", "print(0)" } },
  { "markdown", { "# Heading", "", "content", "", "## Child", "", "more content", "", "# Next", "" } },
  { "tex", { "\\begin{document}", "\\section{Heading}", "text", "more text", "\\end{document}" } },
}) do
  fixture(case[1], case[2])
  assert(vim.wo.foldmethod == "expr", "Missing native TS folding: " .. case[1])
  normal("zM")
  local found = false
  for row = 1, #case[2] do
    found = found or vim.fn.foldclosed(row) ~= -1
  end
  assert(found, "No computed folds: " .. case[1])
end

-- A parser with no folds query must also use indent.
local query_get = vim.treesitter.query.get
vim.treesitter.query.get = function(lang, kind)
  if kind == "folds" then
    return nil
  end
  return query_get(lang, kind)
end
fixture("lua", { "outer", "  body", "  body", "last" })
assert(vim.wo.foldmethod == "indent")
vim.treesitter.query.get = query_get

-- Do not take over diff, terminal/picker buffers or floating windows.
vim.cmd("diffthis")
local diff_method = vim.wo.foldmethod
folding.attach(vim.api.nvim_get_current_win())
assert(diff_method == "diff" and vim.wo.foldmethod == "diff")
vim.cmd("diffoff")
vim.wait(30)
assert(vim.wo.foldmethod == "expr", "Leaving diff did not select the restored Tree-sitter query")

-- A diff transition before deferred initialization must not strand level at 99.
vim.cmd("enew!")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "outer", "  body", "  body", "last" })
vim.bo.filetype = "unknown_folding_test"
vim.cmd("diffthis")
vim.wait(30)
assert(vim.wo.foldmethod == "diff")
vim.cmd("diffoff")
assert(
  vim.wait(1000, function()
    return vim.wo.foldlevel ~= 99
  end),
  "Leaving diff stranded initial fold level"
)
local special = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(special)
vim.bo[special].filetype = "lua"
local special_method = vim.wo.foldmethod
folding.attach(vim.api.nvim_get_current_win())
assert(vim.wo.foldmethod == special_method, "Special buffer foldmethod was overwritten")

-- The only custom fold keys are count-to-level and preview; K stays native.
require("core.keymaps").setup()
for _, key in ipairs({ "zM", "zR", "zm", "zr", "za", "zo", "zc", "zE", "zx", "zX" }) do
  assert(vim.fn.maparg(key, "n") == "", "Native key was overridden: " .. key)
end
local k = vim.fn.maparg("K", "n", false, true)
assert(vim.deep_equal(k, native_k), "Core folding setup changed K")
fixture("unknown_folding_test", { "outer", "  inner", "    body", "    body", "  last", "end" })
vim.api.nvim_feedkeys("1zS", "xt", false)
assert(vim.wo.foldlevel == 1)
assert(vim.fn.foldclosed(3) == 3)

-- Fold text uses display cells for tabs/wide characters, and remains bounded.
local wide_buf, wide_win =
  fixture("unknown_folding_test", { "\t中文中文中文中文中文", "  body", "  body", "last" })
vim.wo.foldmethod = "manual"
vim.cmd("1,4fold")
vim.api.nvim_win_set_width(wide_win, 19)
local wide_text = vim.fn.foldtextresult(1)
local available = vim.fn.getwininfo(wide_win)[1].width - vim.fn.getwininfo(wide_win)[1].textoff
assert(vim.fn.strdisplaywidth(wide_text) <= available and wide_text:find("  󰁂 3", 1, true))
vim.api.nvim_win_set_width(wide_win, 5)
assert(vim.fn.strdisplaywidth(vim.fn.foldtextresult(1)) <= vim.fn.getwininfo(wide_win)[1].width)
vim.api.nvim_win_set_width(wide_win, 40)
local many = {}
for row = 1, 250 do
  many[row] = ("line %d"):format(row)
end
vim.api.nvim_buf_set_lines(wide_buf, 0, -1, false, many)
vim.cmd("1,250fold")
local large_buf, large_win = folding.preview()
assert(vim.api.nvim_buf_line_count(large_buf) == 200)
assert(vim.api.nvim_win_get_config(large_win).title[1][1]:find("first 200 shown", 1, true))
vim.api.nvim_win_close(large_win, true)

print("Native folding, highlighted text, preview, filetypes and window lifecycle checks passed")
