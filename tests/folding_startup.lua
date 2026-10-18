-- Exercise the real lazy.nvim/filetype lifecycle, not just the folding module.
local function check()
  local plugins = require("lazy.core.config").plugins
  assert(not plugins["nvim-ufo"] and not plugins["promise-async"])
  assert(not package.loaded.ufo)
  for _, key in ipairs({ "zM", "zR", "zm", "zr", "zx", "zX", "zE" }) do
    assert(vim.fn.maparg(key, "n") == "", "Native key overridden: " .. key)
  end
  local fixtures = {
    lua = { "local function f()", "  if true then", "    print(1)", "    print(2)", "  end", "end" },
    py = { "def f():", "    if True:", "        print(1)", "        print(2)", "    return 0" },
    md = { "# Heading", "", "hello", "", "## Child", "", "more text", "", "# Next" },
    tex = { "\\begin{document}", "\\section{Test}", "text", "more text", "\\end{document}" },
  }
  for _, extension in ipairs({ "lua", "py", "md", "tex" }) do
    local path = vim.env.NVIM_TEST_TMP .. "/folding." .. extension
    vim.fn.writefile(fixtures[extension], path)
    vim.cmd.edit(path)
    assert(
      vim.wait(2000, function()
        return vim.wo.foldlevel ~= 99
      end),
      "Initialization timeout: " .. extension
    )
    assert(vim.wo.foldmethod == "expr", "Wrong folding source: " .. extension)
    vim.cmd("normal! zM")
    local first
    for row = 1, #fixtures[extension] do
      if vim.fn.foldclosed(row) ~= -1 then
        first = vim.fn.foldclosed(row)
        break
      end
    end
    assert(first, "No folds: " .. extension)
    assert(vim.fn.foldtextresult(first):find("󰁂", 1, true), "Missing hidden line count")
    vim.api.nvim_win_set_cursor(0, { first, 0 })
    local editing_win = vim.api.nvim_get_current_win()
    vim.api.nvim_feedkeys("zK", "xt", false)
    local float = vim.b.lsp_floating_preview
    assert(float and vim.api.nvim_win_is_valid(float), "zK failed: " .. extension)
    assert(vim.api.nvim_get_current_win() == editing_win)
    vim.api.nvim_win_close(float, true)
    vim.cmd("normal! zR")
    assert(vim.fn.foldclosed(first) == -1)
    if extension == "tex" and require("languages").is_enabled("latex") then
      assert(vim.b.tex_tools_generation and not vim.b.vimtex)
      assert(vim.fn.maparg("K", "n") == "", "TeX must keep native LSP hover")
    end
  end
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
  print("Real startup folding and preview passed: " .. (vim.env.NVIM_TEST_SCENARIO or "default"))
end

vim.defer_fn(function()
  local ok, err = xpcall(check, debug.traceback)
  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  end
  vim.cmd("qa!")
end, 100)
