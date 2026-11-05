local api = vim.api
vim.cmd("enew!")
vim.bo.filetype = "markdown"
vim.b.completion_tools_sources = { "snippets" }
vim.bo.expandtab, vim.bo.shiftwidth, vim.bo.autoindent, vim.bo.indentexpr = true, 2, false, ""
function _G.snippet_config_reset(filetype)
  if package.loaded.snippet_tools then
    require("snippet_tools").stop()
  end
  local cmp = package.loaded.completion_tools
  if cmp then
    cmp.hide()
  end
  vim.cmd("enew!")
  vim.bo.filetype = filetype or "markdown"
  vim.b.completion_tools_sources = { "snippets" }
  vim.bo.expandtab, vim.bo.shiftwidth, vim.bo.autoindent, vim.bo.indentexpr = true, 2, false, ""
end
local timer = vim.uv.new_timer()
timer:start(
  0,
  15,
  vim.schedule_wrap(function()
    local cmp = package.loaded.completion_tools
    local item = cmp and cmp.get_selected_item()
    local row = vim.fn.screenpos(api.nvim_get_current_win(), 1, 1).row
    local screen = {}
    if row > 0 then
      for col = 1, math.min(vim.o.columns, 120) do
        screen[#screen + 1] = vim.fn.screenstring(row, col)
      end
    end
    local state = {
      lines = api.nvim_buf_get_lines(0, 0, -1, false),
      mode = api.nvim_get_mode().mode,
      engine = require("integrations.snippets").engine(),
      filetype = vim.bo.filetype,
      legacy_loaded = package.loaded.luasnip ~= nil,
      errors = config_test_errors,
      loaded = package.loaded.snippet_tools ~= nil,
      screen = table.concat(screen),
      menu = cmp and cmp.is_menu_visible() or false,
      selected = item and item.label,
      visual = vim.fn.getpos("v"),
      cursor = api.nvim_win_get_cursor(0),
      fold = vim.fn.foldclosed(1),
      foldlevel = vim.wo.foldlevel,
      native = package.loaded.snippet_tools and require("snippet_tools").inspect() or { active = false },
    }
    vim.fn.writefile({ vim.json.encode(state) }, vim.env.NVIM_SNIPPET_STATE)
  end)
)
api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    timer:stop()
    timer:close()
  end,
})
