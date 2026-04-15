local conds = require("templates.snippets.utils.conditions")

--- Some snippets modified from `https://github.com/mireq/luasnip-snippets/blob/main/lua/luasnip_snippets/python.lua`
local function has_ts_ancestor(node, type)
  if not node then
    return false
  end

  while node do
    print(node:type())
    if node:type() == type then
      return true
    end
    node = node:parent()
  end

  return false
end

local inside_node = function(node_type)
  local cursor = vim.api.nvim_win_get_cursor(0)
  -- Check the first character of the previous line
  cursor = { math.max(0, cursor[1] - 2), 0 }
  local node_cur = vim.treesitter.get_node({ bufnr = 0, pos = cursor })

  return has_ts_ancestor(node_cur, node_type)
end

local function in_class()
  return inside_node("class_definition")
end

return
-- Normal snippets
{

  --- Imports [[[
  s(
    { trig = "fr", desc = "From ... import ... statement" },
    fmta([[from <module> import <name>]], {
      module = i(1, "MODULE"),
      name = i(2, "NAME"),
    }),
    { show_condition = conds.line_begin }
  ),
  s(
    { trig = "fras", desc = "From ... import ... as ... statement" },
    fmta([[from <module> import <name> as <alias>]], {
      module = i(1, "MODULE"),
      name = i(2, "NAME"),
      alias = i(3, "ALIAS"),
    }),
    { show_condition = conds.line_begin }
  ),
  s(
    { trig = "im", desc = "import ... statement" },
    fmta([[import <name>]], {
      name = i(1, "NAME"),
    }),
    { show_condition = conds.line_begin }
  ),
  s(
    { trig = "imas", desc = "import ... as ... statement" },
    fmta([[import <name> as <alias>]], {
      name = i(1, "NAME"),
      alias = i(2, "ALIAS"),
    }),
    { show_condition = conds.line_begin }
  ),
  --- ]]]

  s(
    { trig = "main", desc = "Main" },
    fmta(
      [[
    if __name__ == "__main__":
        <args>
    ]],
      {
        args = i(0, "pass"),
      }
    )
  ),

  s(
    { trig = "ignore", name = "Linting ignore", desc = "Ignore linting error\nPlaced at the end of the line" },
    { t("# noqa: E"), i(1, "402") }
  ),

  s(
    { trig = "eq", desc = { "`__eq__`", "\tShould `from typing import override`" } },
    fmta(
      [[
      @override
      def __eq__(self, other):
          <>
    ]],
      { i(1, "pass") }
    )
  ),
  s(
    { trig = "ne", desc = { "`__ne__`", "\tShould `from typing import override`" } },
    fmta(
      [[
      @override
      def __ne__(self, other):
          <>
    ]],
      { i(1, "pass") }
    )
  ),
  s(
    { trig = "lt", desc = "`__lt__`" },
    fmta(
      [[
      def __lt__(self, other):
          <>
    ]],
      { i(1, "pass") }
    )
  ),
  s(
    { trig = "le", desc = "`__le__`" },
    fmta(
      [[
      def __le__(self, other):
          <>
    ]],
      { i(1, "pass") }
    )
  ),
  s(
    { trig = "gt", desc = "`__gt__`" },
    fmta(
      [[
      def __gt__(self, other):
          <>
    ]],
      { i(1, "pass") }
    )
  ),
  s(
    { trig = "ge", desc = "`__ge__`" },
    fmta(
      [[
      def __ge__(self, other):
          <>
    ]],
      { i(1, "pass") }
    )
  ),
  s(
    { trig = "cmp", desc = "`__cmp__`" },
    fmta(
      [[
      def __cmp__(self, other):
          <>
    ]],
      { i(1, "pass") }
    )
  ),

  s(
    { trig = "class", desc = "Class definition" },
    fmta(
      [[
        class <name>():
            <content>
      ]],
      {
        name = i(1, "NAME"),
        -- base = i(2, "BASE"),
        content = i(2, "pass"),
      }
    )
  ),
}
