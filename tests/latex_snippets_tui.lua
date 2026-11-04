local api = vim.api
function _G.latex_snippet_reset(beamer)
  if package.loaded.snippet_tools then
    require("snippet_tools").stop()
  end
  if package.loaded.completion_tools then
    require("completion_tools").hide()
  end
  vim.cmd("enew!")
  vim.bo.filetype = "tex"
  vim.b.completion_tools_sources = { "snippets" }
  vim.bo.expandtab, vim.bo.shiftwidth, vim.bo.autoindent, vim.bo.indentexpr = true, 2, false, ""
  if beamer then
    api.nvim_buf_set_lines(0, 0, -1, false, {
      "\\documentclass{beamer}",
      "\\begin{document}",
      "",
      "\\end{document}",
    })
    api.nvim_win_set_cursor(0, { 3, 0 })
  end
end
latex_snippet_reset()
local timer = vim.uv.new_timer()
timer:start(
  0,
  15,
  vim.schedule_wrap(function()
    local cmp = package.loaded.completion_tools
    local item = cmp and cmp.get_selected_item()
    local screen, row = {}, vim.fn.screenpos(api.nvim_get_current_win(), vim.fn.line("."), 1).row
    if row > 0 then
      for col = 1, math.min(vim.o.columns, 120) do
        screen[#screen + 1] = vim.fn.screenstring(row, col)
      end
    end
    local mode = api.nvim_get_mode().mode
    local selection = mode == "s"
        and table.concat(
          vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
            type = "v",
            exclusive = vim.o.selection == "exclusive",
          }),
          "\n"
        )
      or ""
    vim.fn.writefile({
      vim.json.encode({
        lines = api.nvim_buf_get_lines(0, 0, -1, false),
        mode = mode,
        engine = require("integrations.snippets").engine(),
        errors = config_test_errors,
        loaded = package.loaded.snippet_tools ~= nil,
        screen = table.concat(screen),
        selection = selection,
        menu = cmp and cmp.is_menu_visible() or false,
        selected = item and item.label,
        native = package.loaded.snippet_tools and require("snippet_tools").inspect() or { active = false },
      }),
    }, vim.env.NVIM_SNIPPET_STATE)
  end)
)
api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    timer:stop()
    timer:close()
  end,
})
