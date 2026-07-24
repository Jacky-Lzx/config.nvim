local todo_comment_snippets = require("snippets.generators.todo-comment").generate_todo_comment_snippets()

local function date_and_time(
  _,
  _, -- parent snippet or parent node
  user_args -- user_args from opts.user_args
)
  -- require("snacks.notify").info(user_args)

  if user_args == "date" then
    return os.date("%Y.%m.%d")
  else -- user_args[0] == "datetime"
    return os.date("%Y.%m.%d %H:%M:%S")
  end
end

return {
  s({ trig = "date", desc = "Date" }, { f(date_and_time, {}, { user_args = { "date" } }) }),
  s({ trig = "datetime", desc = "Date & time" }, { f(date_and_time, {}, { user_args = { "datetime" } }) }),

  unpack(todo_comment_snippets),
}
