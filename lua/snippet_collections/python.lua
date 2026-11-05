local s = require("snippet_tools")
local h = require("snippet_collections.helpers")
local def, fmt = h.define, s.fmta
local result = {
  def(
    "fr",
    "From ... import ... statement",
    fmt("from <module> import <name>", {
      module = s.i(1, "MODULE"),
      name = s.i(2, "NAME"),
    }),
    { show_condition = h.line_begin }
  ),
  def(
    "fras",
    "From ... import ... as ... statement",
    fmt("from <module> import <name> as <alias>", {
      module = s.i(1, "MODULE"),
      name = s.i(2, "NAME"),
      alias = s.i(3, "ALIAS"),
    }),
    { show_condition = h.line_begin }
  ),
  def("im", "import ... statement", fmt("import <>", { s.i(1, "NAME") }), { show_condition = h.line_begin }),
  def(
    "imas",
    "import ... as ... statement",
    fmt("import <> as <>", { s.i(1, "NAME"), s.i(2, "ALIAS") }),
    { show_condition = h.line_begin }
  ),
  def(
    "main",
    "Main",
    fmt(
      [[
    if __name__ == "__main__":
        <>
  ]],
      { s.i(0, "pass") }
    )
  ),
  def("ignore", "Ignore linting error\nPlaced at the end of the line", { s.t("# noqa: E"), s.i(1, "402"), s.i(0) }),
  def(
    "class",
    "Class definition",
    fmt(
      [[
    class <>():
        <><>
  ]],
      { s.i(1, "NAME"), s.i(2, "pass"), s.i(0) }
    )
  ),
}
for _, name in ipairs({ "eq", "ne", "lt", "le", "gt", "ge", "cmp" }) do
  result[#result + 1] = def(
    name,
    "`__" .. name .. "__`",
    fmt(
      (name == "eq" or name == "ne") and "@override\ndef __<>__(self, other):\n    <><>"
        or "def __<>__(self, other):\n    <><>",
      { s.t(name), s.i(1, "pass"), s.i(0) }
    )
  )
end
return result
