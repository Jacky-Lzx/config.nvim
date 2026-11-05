local s = require("snippet_tools")
local h = require("snippet_collections.helpers")
local def, fmt = h.define, s.fmta
return {
  def("stylua-ignore", "Ignore stylua", { s.t("-- stylua: ignore"), s.c(1, { "", " start", " end" }), s.i(0) }, {
    show_condition = h.line_begin,
  }),
  def(
    "codespell-ignore",
    "Ignore codespell (Place at the end of the line)",
    fmt([[-- codespell:ignore "<>"]], { s.i(0, "<WORD>") })
  ),
  def("typos-ignore", "Ignore typos", { s.t("-- typos: ignore"), s.i(0) }, { show_condition = h.line_begin }),
  def(
    "req",
    "Require module",
    fmt([[local <> = require("<>")]], {
      s.d(2, function(args)
        return s.i(1, args[1]:match("[^.]+$") or args[1])
      end, { 1 }),
      s.i(1),
    })
  ),
  def(
    "lfun",
    "Local function",
    fmt(
      [[
    local function <>(<>)
      <>
    end
  ]],
      { s.i(1), s.i(2), s.i(0) }
    )
  ),
  def(
    "mfun",
    "Method function",
    fmt(
      [[
    <>.<> = function(<>)
      <>
    end
  ]],
      { s.i(1, "M"), s.i(2), s.i(3), s.i(0) }
    )
  ),
  def(
    "fun",
    "Function",
    fmt(
      [[
    function(<>)
      <>
    end
  ]],
      { s.i(1), s.i(0) }
    )
  ),
  def("inspect", "Inspect variable using snacks.debug", { s.t('require("snacks.debug").inspect('), s.i(0), s.t(")") }),
  def("print", "Print variable using snacks.notify", { s.t('require("snacks.notify").info('), s.i(0), s.t(")") }),
  def(
    "snippet",
    "Native snippet definition",
    s.fmta(
      [=[
    {
      trigger = "<trigger>",
      description = "<description>",
      body = s.fmta([[
        <body>
      ]], {<nodes>}),<condition>
    }
  ]=],
      {
        trigger = s.i(1),
        description = s.i(2),
        body = s.i(3),
        nodes = s.i(4),
        condition = s.c(5, { "", { s.t("\n  show_condition = "), s.i(1), s.t(",") } }),
      }
    )
  ),
  def("command", "Neovim command", s.fmt([[<CMD>{}<ESC>]], { s.i(0) })),
}
