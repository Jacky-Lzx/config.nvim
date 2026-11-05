local s = require("snippet_tools")
local def = require("snippet_collections.helpers").define
return {
  def("bf", "Bold text", s.fmta("#strong[<>] <>", { s.i(1), s.i(0) })),
  def(
    "figure",
    "Figure",
    s.fmt([[#figure(image("./Figures/{}", width: 80%), caption: [{}]) <fig:{}>{}]], {
      s.i(1),
      s.i(2),
      s.f(function(args)
        return args[1]:gsub("%.[^.]*$", "")
      end, { 1 }),
      s.i(0),
    })
  ),
}
