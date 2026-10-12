local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)
vim.g.mapleader = " "
package.preload["mini.comment"] = function()
  error("Commenting and TODO snippets must not load mini.comment")
end
require("core.keymaps").setup()

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), "xt", false)
end
local lines = { "local x = 1", "local y = 2", "local z = 3" }
local function reset()
  feed("<Esc>")
  vim.cmd.enew({ bang = true })
  vim.bo.commentstring = "-- %s"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end
local function expect(expected)
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(vim.deep_equal(actual, expected), vim.inspect({ actual = actual, expected = expected }))
end

reset()
feed("<leader>/")
expect({ "-- local x = 1", lines[2], lines[3] })
feed("<leader>/")
expect(lines)
feed("2<leader>/")
expect({ "-- local x = 1", "-- local y = 2", lines[3] })
feed("2<leader>/")
expect(lines)
feed("<leader>/j.")
expect({ "-- local x = 1", "-- local y = 2", lines[3] })

for _, selection in ipairs({ "ggVj", "gg0vjl", "gg0<C-v>j" }) do
  reset()
  feed(selection .. "<leader>/")
  expect({ "-- local x = 1", "-- local y = 2", lines[3] })
  feed(selection .. "<leader>/")
  expect(lines)
end

reset()
feed("gcip")
expect({ "-- local x = 1", "-- local y = 2", "-- local z = 3" })
feed("dgc")
expect({ "" })

local commentstring = require("snippets.utils.commentstring")
vim.bo.commentstring = "/* %s */"
assert(commentstring.at_cursor() == "/* %s */", "Missing parsers must use the buffer commentstring")

-- Choose the deepest injected language that has a commentstring, ignoring
-- deeper comment grammars and languages outside the current position.
local get_parser = vim.treesitter.get_parser
local get_filetypes = vim.treesitter.language.get_filetypes
local get_option = vim.filetype.get_option
local function tree(language, children, contains)
  return {
    contains = function(_, range)
      assert(vim.deep_equal(range, { 0, 0, 0, 1 }), "Cursor coordinates must be zero based")
      return contains ~= false
    end,
    lang = function()
      return language
    end,
    children = function()
      return children or {}
    end,
  }
end
vim.treesitter.get_parser = function()
  return tree("html", { tree("lua", { tree("comment") }), tree("python", nil, false) })
end
vim.treesitter.language.get_filetypes = function(language)
  return { language }
end
vim.filetype.get_option = function(filetype, option)
  assert(option == "commentstring")
  return ({ html = "<!-- %s -->", lua = "-- %s", python = "# %s", comment = "" })[filetype]
end
assert(commentstring.at_cursor() == "-- %s", "TODO snippets must respect injected languages")
vim.treesitter.get_parser, vim.treesitter.language.get_filetypes, vim.filetype.get_option =
  get_parser, get_filetypes, get_option

-- Verify a real Markdown injection with Neovim's bundled Markdown/Lua parsers.
vim.cmd("filetype plugin on")
reset()
vim.bo.filetype = "markdown"
vim.bo.commentstring = "<!-- %s -->"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# Title", "", "```lua", "local value = 1", "```" })
vim.treesitter.get_parser(0, "markdown"):parse(true)
vim.api.nvim_win_set_cursor(0, { 4, 0 })
assert(commentstring.at_cursor() == "-- %s")
feed("<leader>/")
assert(vim.api.nvim_buf_get_lines(0, 3, 4, false)[1] == "-- local value = 1")

-- Exercise actual LuaSnip expansion after removing the former plugin dependency.
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/LuaSnip")
local luasnip = require("luasnip")
luasnip.setup({})
for _, delimiters in ipairs({ "-- %s", "# %s", "<!-- %s -->" }) do
  reset()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
  vim.bo.commentstring = delimiters
  local snippets = require("snippets.generators.todo-comment").generate_todo_comment_snippets()
  luasnip.snip_expand(snippets[1])
  local left, right = delimiters:match("^(.*)%%s(.*)$")
  local expanded = vim.api.nvim_get_current_line()
  assert(expanded:find(vim.trim(left) .. " TODO:", 1, true), "TODO expansion lost its opening comment")
  assert(expanded:sub(-#right) == right or right == "", "TODO expansion lost its closing comment")
  luasnip.unlink_current()
end
assert(not package.loaded["mini.comment"])
print("Native comment mappings, counts, repeat, selections, textobjects and TODO snippets passed")
