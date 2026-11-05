local s = require("snippet_tools")
local def = require("snippet_collections.helpers").define
local function date()
  return os.date("%Y.%m.%d")
end
local result = {
  def("date", "Date", { s.f(date), s.i(0) }),
  def("datetime", "Date & time", { s.f(function()
    return os.date("%Y.%m.%d %H:%M:%S")
  end), s.i(0) }),
}
local function delimiter(side)
  return s.f(function()
    local format = require("snippets.utils.commentstring").at_cursor()
    local left, right = format:match("^(.*)%%s(.*)$")
    return vim.trim((side == "left" and left or right) or "")
  end)
end
local function signature()
  return s.c(2, {
    { s.t("<"), s.f(date), s.t(", lzx>"), s.i(1) },
    { s.t("<"), s.f(date), s.t(">"), s.i(1) },
    "",
  })
end
for _, item in ipairs({
  { "todo", { "TODO" } },
  { "fix", { "FIX", "BUG", "ISSUE", "FIXIT" } },
  { "hack", { "HACK" } },
  { "warn", { "WARN", "WARNING", "XXX" } },
  { "perf", { "PERF", "PERFORMANCE", "OPTIM", "OPTIMIZE" } },
  { "note", { "NOTE", "INFO" } },
}) do
  local aliases = {}
  for _, alias in ipairs(item[2]) do
    aliases[#aliases + 1] = { s.i(1, alias) }
  end
  result[#result + 1] = def(item[1], table.concat(item[2], "|") .. " comment", {
    delimiter("left"),
    s.t(" "),
    #aliases == 1 and s.t(item[2][1]) or s.c(1, aliases),
    s.t(": "),
    s.i(3),
    s.t(" "),
    signature(),
    s.t(" "),
    delimiter("right"),
    s.i(0),
  })
end
return result
