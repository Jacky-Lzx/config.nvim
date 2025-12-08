local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

local conds = require("templates.snippets.utils.conditions")

return {
  -- stylua: ignore
  s({ trig = "hello", desc = "Print Hello world" },
    { t('println!("Hello world");') },
    { show_condition = conds.line_begin }
  ),
}
