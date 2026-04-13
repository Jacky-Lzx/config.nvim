local todo_comment_snippets = require("templates.snippets.generators.todo-comment").generate_todo_comment_snippets()

return {
  s({ trig = "date", desc = "Date" }, { t(os.date("%Y.%m.%d")) }),
  s({ trig = "datetime", desc = "Date & time" }, { t(os.date("%Y.%m.%d %H:%M:%S")) }),

  unpack(todo_comment_snippets),
}
