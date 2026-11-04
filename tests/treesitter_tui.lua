local api = vim.api
local result = assert(vim.env.TREESITTER_TUI_RESULT)
local stage_file = assert(vim.env.TREESITTER_TUI_STAGE)
local stage, source_buf, source_win = "initial", nil, nil
local timer = vim.uv.new_timer()
local function mark(value)
  stage = value
  vim.fn.writefile({ value }, stage_file)
end
local function check()
  if stage == "initial" then
    if not vim.g.did_very_lazy then
      return
    end
    assert(not require("lazy.core.config").plugins["nvim-treesitter"])
    assert(not vim.g.loaded_nvim_treesitter and not package.loaded["nvim-treesitter"])
    vim.cmd("enew!")
    source_buf, source_win = api.nvim_get_current_buf(), api.nvim_get_current_win()
    vim.bo.filetype = "lua"
    mark("lua")
  elseif stage == "lua" and api.nvim_get_mode().mode == "n" and api.nvim_get_current_line() == "local value = 1" then
    assert(vim.treesitter.highlighter.active[source_buf])
    assert(not vim.treesitter.get_parser(source_buf):parse()[1]:root():has_error())
    vim.cmd("vnew")
    api.nvim_buf_set_lines(0, 0, -1, false, { "# Title", "", "```lua", "local answer = 42", "```" })
    vim.bo.filetype = "markdown"
    mark("markdown")
  elseif stage == "markdown" and require("render-markdown.state").enabled then
    local parser = vim.treesitter.get_parser(0)
    parser:parse(true)
    local languages = {}
    parser:for_each_tree(function(_, tree)
      languages[tree:lang()] = true
    end)
    assert(languages.markdown and languages.lua, vim.inspect(languages))
    assert(api.nvim_buf_get_lines(0, 0, 1, false)[1] == "# Title", "Rendering must preserve Markdown source")
    mark("markdown_edit")
  elseif
    stage == "markdown_edit"
    and api.nvim_get_mode().mode == "n"
    and api.nvim_buf_get_lines(0, 0, 1, false)[1] == "# Title edited"
  then
    vim.cmd("new")
    api.nvim_buf_set_lines(0, 0, -1, false, {
      "\\documentclass{article}",
      "\\begin{document}",
      "\\section{Hello}",
      "$x_1$",
      "\\end{document}",
    })
    vim.bo.filetype = "tex"
    api.nvim_win_set_cursor(0, { 4, 0 })
    assert(vim.treesitter.language.get_lang("tex") == "latex")
    mark("tex")
  elseif stage == "tex" and api.nvim_get_current_line() == "$x_2$" then
    assert(vim.treesitter.highlighter.active[api.nvim_get_current_buf()])
    assert(not vim.treesitter.get_parser(0):parse(true)[1]:root():has_error())
    api.nvim_set_current_win(source_win)
    assert(api.nvim_get_current_buf() == source_buf and vim.bo[source_buf].modified)
    assert(api.nvim_buf_get_lines(source_buf, 0, -1, false)[1] == "local value = 1")
    assert(not package.loaded["nvim-treesitter"])
    assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
    timer:stop()
    timer:close()
    vim.fn.writefile({
      "PASS standalone runtime: Lua typing, Markdown rendering/injection/editing, TeX editing and source preservation",
    }, result)
    vim.cmd("qa!")
  end
end
timer:start(
  20,
  20,
  vim.schedule_wrap(function()
    local ok, err = xpcall(check, debug.traceback)
    if not ok then
      timer:stop()
      timer:close()
      vim.fn.writefile(vim.split(err, "\n", { plain = true }), result)
      vim.cmd("cquit 1")
    end
  end)
)
