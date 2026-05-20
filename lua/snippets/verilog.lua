local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local rep = require("luasnip.extras").rep

local function file_name_without_extension()
  local full_path = vim.api.nvim_buf_get_name(0)
  local file_name = vim.fn.fnamemodify(full_path, ":t:r")
  return file_name
end

-- new line
-- local nl = t({ "", "" })

return {
  -- stylua: ignore
  s({ trig = "module", desc = "Module Block" }, {
    t("module "), i(1, file_name_without_extension()), t({ " (" }),
    t({ "", "  " }), i(2, "PORTS"),
    t({ "", ");" }),
    t({ "", "  " }), i(0),
    t({ "", "endmodule" }),
  }),
  -- stylua: ignore
  s({ trig = "if", desc = "If Statement" }, {
    t("if ("), i(1, "CONDITION"), t(") begin"),
    t({ "", "  " }), i(0),
    t({ "", "end" }),
  }),
  -- stylua: ignore
  s({ trig = "if-else", desc = "If-Else Statement", wordTrig = false }, {
    t("if ("), i(1, "CONDITION"), t(") begin"),
    t({ "", "  " }), i(2),
    t({ "", "end else begin" }),
    t({ "", "  " }), i(0),
    t({ "", "end" }),
  }),
  -- stylua: ignore
  s({ trig = "else", desc = "Else Statement" }, {
    t("else begin"),
    t({ "", "  " }), i(0),
    t({ "", "end" }),
  }),
  -- stylua: ignore
  s({ trig = "case", desc = "Case Statement" }, {
    t("case ("), i(1, "EXPRESSION"), t(")"),
    t({ "", "  " }), i(2), t(":"), i(3),
    t({ "", "  default:" }), i(4),
    t({ "", "endcase" }),
  }),
  -- stylua: ignore
  s({ trig = "always", desc = "Always Block" }, {
    t("always @(posedge "), i(1, "SIGNAL"), t(") begin"),
    t({ "", "  " }), i(0),
    t({ "", "end" }),
  }),
  -- stylua: ignore
  s({ trig = "initial", desc = "Initial Block" }, {
    t("initial begin"),
    t({ "", "  " }), i(0),
    t({ "", "end" }),
  }),
  -- stylua: ignore
  s({ trig = "for", desc = "For Loop" }, {
    t("for ("), i(1, "i"), t("= 0; "), rep(1), t(" < "), i(2, "N"), t("; "), rep(1), t(" = "), rep(1), t(" + 1) begin"),
    t({ "", "  " }), i(0),
    t({ "", "end" }),
  }),
}
