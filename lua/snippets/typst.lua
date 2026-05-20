local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
-- local fmta = require("luasnip.extras.fmt").fmta
local fmt = require("luasnip.extras.fmt").fmt
local f = ls.function_node

return {
  -- stylua: ignore
  s(
    { trig = "bf", desc = "Bold text" },
    fmta([[
        #strong[<>] 
      ]],
      { i(1) }
    )
  ),

  s(
    { trig = "figure", desc = "Figure" },
    fmt(
      [[
        #figure(image("{}{}", width: 80%), caption: [{}]) <fig:{}>
      ]],
      {
        t("./Figures/"),
        i(1),
        i(2),
        f(function(args, _, _)
          -- Remove extension str
          return args[1][1]:gsub("%.[^.]*$", "")
        end, { 1 }),
      }
    )
  ),
}
