return {
  name = "[Markdown] Preview (gh)",
  priority = 100,
  builder = function()
    local file = vim.fn.expand("%:p")
    local port = 3333

    -- The Logic:
    -- 1. Look for a PID using the port and kill it if found.
    -- 2. Wait a split second for the port to actually clear.
    -- 3. Launch the browser in the background.
    -- 4. Start the new server.
    local cmd_str = string.format(
      [[bash -c "lsof -ti:%d | xargs kill -9 2>/dev/null; ]]
        .. [[sleep 0.2; ]]
        .. [[(sleep 0.5 && open -na 'Google Chrome' --args --incognito --app=http://localhost:%d) & ]]
        .. [[gh markdown-preview --disable-auto-open --port %d '%s'"]],
      port,
      port,
      port,
      file
    )

    return {
      cmd = cmd_str,
      components = {
        { "on_exit_set_status" },
      },
    }
  end,
  condition = {
    filetype = { "markdown" },
  },
}
