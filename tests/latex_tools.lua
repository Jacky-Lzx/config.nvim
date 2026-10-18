-- Full-config integration: commands, real input, key ownership, and snippet context.
local function check()
  local plugins = require("lazy.core.config").plugins
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
  buffer("$\\frac{x}{y}$")
  assert(plugins["tex-tools.nvim"]._.loaded)
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
  keys("dse")
  assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") == "body")
  buffer("\\begin{tabular}{cc}\nx & y \\\\\n\\end{tabular}")
  at("x")
  keys("yit")
  assert(vim.fn.getreg('"') == "x", "Cell text object did not select cell contents")

  local conditions = require("snippets.tex.utils.math_conditions")
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

  -- The completion/Enter composition remains the existing Blink -> pairs chain.
  vim.api.nvim_exec_autocmds("InsertEnter", {})
  local blink = require("lazy.core.plugin").values(plugins["blink.cmp"], "opts", false)
  assert(require("tex-tools.config").options.smart_enter == false)
  assert(blink.keymap["<CR>"][2]() == require("pairs").expr("<CR>"))
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
