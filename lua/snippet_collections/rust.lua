local s = require("snippet_tools")
local h = require("snippet_collections.helpers")
return {
  h.define(
    "hello",
    "Print Hello world",
    { s.t('println!("Hello world");'), s.i(0) },
    { show_condition = h.line_begin }
  ),
}
