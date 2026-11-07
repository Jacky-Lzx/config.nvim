local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)
require("core.commands").setup()
assert(vim.fn.exists(":Titlecase") == 2)

local count = 0
local function check(name, lines, keys, expected, selection)
  vim.cmd.enew({ bang = true })
  vim.o.selection = selection or "inclusive"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
  assert(
    vim.deep_equal(expected, vim.api.nvim_buf_get_lines(0, 0, -1, false)),
    name .. ": " .. vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))
  )
  count = count + 1
end

check("no visual marks", { "the hELLO world" }, ":Titlecase<CR>", { "The Hello World" })
-- :Titlecase operates on the Ex line range, including character/block selections.
check(
  "characterwise line range",
  { "prefix hELLO wORLD suffix" },
  "gg7lv10l:Titlecase<CR>",
  { "Prefix Hello World Suffix" }
)
check("reverse selection", { "prefix hELLO wORLD suffix" }, "gg17lv10h:Titlecase<CR>", { "Prefix Hello World Suffix" })
check(
  "exclusive",
  { "prefix hELLO wORLD suffix" },
  "gg7lv11l:Titlecase<CR>",
  { "Prefix Hello World Suffix" },
  "exclusive"
)
check(
  "reverse exclusive",
  { "prefix hELLO wORLD suffix" },
  "gg18lv11h:Titlecase<CR>",
  { "Prefix Hello World Suffix" },
  "exclusive"
)
check(
  "multiline range",
  { "prefix hELLO", "the WORLD and SKY", "gOOD bye suffix" },
  "gg7lv2j:Titlecase<CR>",
  { "Prefix Hello", "The World and Sky", "Good Bye Suffix" }
)
check("linewise", { "hELLO world", "the SKY" }, "gg5lVj:Titlecase<CR>", { "Hello World", "The Sky" })
check(
  "blockwise line range",
  { "xx hELLO zz", "yy wORLD zz" },
  "gg3l<C-v>j4l:Titlecase<CR>",
  { "Xx Hello Zz", "Yy World Zz" }
)
check(
  "explicit matching range",
  { "prefix hELLO suffix", "the WORLD" },
  "gg7lv3l<Esc>:1Titlecase<CR>",
  { "Prefix Hello Suffix", "the WORLD" }
)
check(
  "explicit other range",
  { "hELLO world", "the WORLD", "a TITLE" },
  "ggvll<Esc>:2,3Titlecase<CR>",
  { "hELLO world", "The World", "A Title" }
)
check("whole buffer", { "hELLO world", "the WORLD" }, "ggvll<Esc>:%Titlecase<CR>", { "Hello World", "The World" })
check("no range", { "hELLO world", "the WORLD" }, "ggvll<Esc>j:Titlecase<CR>", { "hELLO world", "The World" })
check("empty line", { "" }, ":Titlecase<CR>", { "" })
check("empty middle line", { "hELLO", "", "wORLD" }, "ggvjjo:Titlecase<CR>", { "Hello", "", "World" })
check(
  "short block line",
  { "xx hELLO zz", "", "yy wORLD zz" },
  "gg3l<C-v>2j4l:Titlecase<CR>",
  { "Xx Hello Zz", "", "Yy World Zz" }
)
check("tab conversion", { "\tfirst\tsecond", "\tthird" }, ":ConvertTabToSpace<CR>", { "  first  second", "  third" })

local printed
local original_print = vim.print
vim.print = function(value)
  printed = value
end
vim.cmd.ConfigInfo()
vim.print = original_print
assert(vim.deep_equal(printed, require("config").info()))
count = count + 1
print("commands: " .. count .. " tests passed")
