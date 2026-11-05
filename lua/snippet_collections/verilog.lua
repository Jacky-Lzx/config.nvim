local s = require("snippet_tools")
local def = require("snippet_collections.helpers").define
return {
  def("module", "Module Block", {
    s.t("module "),
    s.d(1, function(_, ctx)
      return s.i(1, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.bufnr), ":t:r"))
    end),
    s.t(" (\n  "),
    s.i(2, "PORTS"),
    s.t("\n);\n  "),
    s.i(0),
    s.t("\nendmodule"),
  }),
  def("if", "If Statement", { s.t("if ("), s.i(1, "CONDITION"), s.t(") begin\n  "), s.i(0), s.t("\nend") }),
  def("if-else", "If-Else Statement", {
    s.t("if ("),
    s.i(1, "CONDITION"),
    s.t(") begin\n  "),
    s.i(2),
    s.t("\nend else begin\n  "),
    s.i(0),
    s.t("\nend"),
  }, { word = false }),
  def("else", "Else Statement", { s.t("else begin\n  "), s.i(0), s.t("\nend") }),
  def("case", "Case Statement", {
    s.t("case ("),
    s.i(1, "EXPRESSION"),
    s.t(")\n  "),
    s.i(2),
    s.t(":"),
    s.i(3),
    s.t("\n  default:"),
    s.i(4),
    s.t("\nendcase"),
    s.i(0),
  }),
  def(
    "always",
    "Always Block",
    { s.t("always @(posedge "), s.i(1, "SIGNAL"), s.t(") begin\n  "), s.i(0), s.t("\nend") }
  ),
  def("initial", "Initial Block", { s.t("initial begin\n  "), s.i(0), s.t("\nend") }),
  def("for", "For Loop", {
    s.t("for ("),
    s.i(1, "i"),
    s.t("= 0; "),
    s.rep(1),
    s.t(" < "),
    s.i(2, "N"),
    s.t("; "),
    s.rep(1),
    s.t(" = "),
    s.rep(1),
    s.t(" + 1) begin\n  "),
    s.i(0),
    s.t("\nend"),
  }),
}
