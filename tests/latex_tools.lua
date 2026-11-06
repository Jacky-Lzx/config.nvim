-- Full-config integration: commands, real input, key ownership, and snippet context.
local function check()
  local plugins = require("config.plugins").nodes()
  assert(not plugins.vimtex and not plugins["nvim-texlabconfig"])
  local function buffer(text)
    vim.cmd("enew!")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text, "\n", { plain = true }))
    vim.bo.filetype = "tex"
    vim.wo.foldenable = false
    vim.treesitter.get_parser(0, "latex"):parse()
  end
  local function at(text)
    for row, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
      local col = line:find(text, 1, true)
      if col then
        vim.api.nvim_win_set_cursor(0, { row, col - 1 })
        return
      end
    end
    error("Missing fixture text: " .. text)
  end
  local function keys(text)
    vim.api.nvim_feedkeys(vim.keycode(text), "xt", false)
  end
  -- Project actions also work when a bibliography is the first opened file.
  vim.cmd("enew!")
  vim.bo.filetype = "bib"
  assert(require("config.plugins").initialized("tex-tools.nvim"))
  assert(not vim.api.nvim_buf_get_commands(0, {}).TexToolsUnwrapEnvironment)
  local tools = require("tex-tools")
  local build, hits = tools.build, 0
  tools.build = function()
    hits = hits + 1
    return true
  end
  vim.fn.maparg("<localleader>ll", "n", false, true).callback()
  tools.build = build
  assert(hits == 1, "First bibliography action did not reach tex-tools")
  for _, ft in ipairs({ "bst", "plaintex" }) do
    vim.cmd("enew!")
    vim.bo.filetype = ft
    assert(vim.fn.maparg("<localleader>ll", "n") ~= "", "Missing build mapping: " .. ft)
  end
  buffer("$\\frac{x}{y}$")
  assert(require("config.plugins").initialized("tex-tools.nvim"))
  local tex = require("tex-tools")
  local original_preview, preview_calls = tex.preview, 0
  assert(type(original_preview) == "function", "Configured tex-tools must provide the unified preview API")
  tex.preview = function()
    preview_calls = preview_calls + 1
    return true
  end
  assert(require("integrations.image_tools").preview() == true)
  assert(preview_calls == 1, "Personal TeX preview must reach the configured tex-tools API")
  tex.preview = original_preview
  assert(vim.api.nvim_buf_get_commands(0, {}).TexToolsCompiler)
  -- Every configured Plug target must exist in the mode where it is invoked.
  for _, mode in ipairs({ "n", "i", "x", "o" }) do
    for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
      if mapping.rhs and mapping.rhs:find("<Plug>(TexTools", 1, true) then
        assert(vim.fn.maparg(mapping.rhs, mode) ~= "", "Missing target: " .. mapping.rhs .. " (" .. mode .. ")")
      end
      assert(not (mapping.rhs or ""):find("vimtex", 1, true))
    end
  end
  -- A buffer-local Space prefix would make every Insert Space wait before
  -- the global pairs.nvim mapping can run, even with its nowait=true flag.
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, "i")) do
    local lhs = vim.keycode(mapping.lhs)
    assert(lhs:sub(1, 1) ~= " " or #lhs == 1, "Insert Space prefix delays typing: " .. mapping.lhs)
  end
  assert(vim.fn.maparg("<Space>li", "n") == "<Cmd>TexToolsInfo<CR>")
  assert(vim.fn.maparg("<Space>lEd", "n") == "<Plug>(TexToolsUnwrapEnvironment)")
  at("x")
  keys("yia")
  assert(vim.fn.getreg('"') == "x", "Argument text object did not select the fraction argument")
  buffer("\\begin{itemize}\n\\item first\n\\item second\n\\end{itemize}")
  at("first")
  keys("yai")
  local item = vim.fn.getreg('"')
  assert(item:find("first", 1, true) and not item:find("second", 1, true), "Native item text object selected a sibling")
  buffer("\\begin{quote}\nbody\n\\end{quote}")
  at("body")
  keys("<Space>lEd")
  assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") == "body")
  buffer("\\begin{tabular}{cc}\nx & y \\\\\n\\end{tabular}")
  at("x")
  keys("yit")
  assert(vim.fn.getreg('"') == "x", "Cell text object did not select cell contents")

  local conditions = require("snippet_collections.tex.context")
  buffer("$x + \\text{words $y$} + z$")
  at("x")
  assert(conditions.fn.math_mode())
  at("words")
  assert(not conditions.fn.math_mode())
  at("y")
  assert(conditions.fn.math_mode(), "Nested formula inside text was excluded")
  buffer("% $x$")
  at("x")
  assert(not conditions.fn.math_mode(), "Comment was treated as math")

  -- The completion/Enter composition remains the completion-tools -> pairs chain.
  vim.api.nvim_exec_autocmds("InsertEnter", {})
  local completion_spec = vim.deepcopy((plugins["completion-tools.nvim"]).opts)
  assert(require("tex-tools.config").options.smart_enter == false)
  assert(completion_spec.keymap["<CR>"][2]() == require("pairs").expr("<CR>"))
  assert(not vim.fn.maparg("<CR>", "i"):find("TexTools", 1, true))
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
  print("LaTeX tools: native text objects, editing, context and Enter ownership passed")
end
vim.defer_fn(function()
  local ok, err = xpcall(check, debug.traceback)
  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  end
  vim.cmd("qa!")
end, 100)
