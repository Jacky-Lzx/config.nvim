local todo_comment_snippets = require("snippets.generators.todo-comment").generate_todo_comment_snippets()
local nodes = require("snippets.utils.nodes")

return {
  s({ trig = "date", desc = "Date" }, { f(nodes.fn_date_and_time, {}, { user_args = { "date" } }) }),
  s({ trig = "datetime", desc = "Date & time" }, { f(nodes.fn_date_and_time, {}, { user_args = { "datetime" } }) }),

  unpack(todo_comment_snippets),
}
