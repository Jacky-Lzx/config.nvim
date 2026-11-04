local function pause(ms)
  coroutine.yield(ms)
end
local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
end
local function check()
  local api = vim.api
  local fold = require("ui_tools.fold")
  assert(fold.enabled and fold.options.suffix == "  󰁂 %d")
  for _, key in ipairs({ "zM", "zR", "zm", "zr", "za", "zo", "zc", "zx", "zX" }) do
    assert(vim.fn.maparg(key, "n") == "", "Native fold key was overridden: " .. key)
  end
  local path = vim.env.NVIM_TEST_TMP .. "/folding-tui.lua"
  vim.fn.writefile({
    "local function outer()",
    "  if true then",
    "    print('你好')",
    "    print('second')",
    "  end",
    "end",
    "return outer",
  }, path)
  vim.cmd.edit(path)
  pause(150)
  assert(vim.wo.foldmethod == "expr" and vim.wo.foldlevel == 2)
  local source = api.nvim_get_current_win()
  feed("zm")
  assert(vim.wo.foldlevel == 1 and vim.fn.foldclosed(3) == 2)
  feed("zM")
  assert(vim.fn.foldclosed(3) == 1)
  assert(vim.fn.foldtextresult(1) == "local function outer()  󰁂 5")
  feed("zK")
  pause(80)
  local preview = vim.b.lsp_floating_preview
  assert(preview and api.nvim_win_is_valid(preview))
  assert(api.nvim_get_current_win() == source, "First preview stole focus")
  feed("zK")
  assert(api.nvim_get_current_win() == preview, "Repeated preview did not focus")
  feed("<Esc>")
  assert(not api.nvim_win_is_valid(preview) and api.nvim_get_current_win() == source)
  feed("1zS")
  assert(vim.wo.foldlevel == 1 and vim.fn.foldclosed(3) == 2)
  feed("zM")
  vim.cmd("vsplit")
  pause(100)
  local split = api.nvim_get_current_win()
  assert(vim.wo[split].foldlevel == 2 and vim.wo[source].foldlevel == 0)
  vim.cmd("wincmd p")
  assert(vim.fn.foldclosed(3) == 1)
  api.nvim_win_close(split, false)
  feed("zR2zm2zr")
  assert(vim.wo.foldlevel == 2 and vim.fn.foldclosed(3) == -1)
  vim.cmd("diffthis")
  pause(50)
  assert(vim.wo.foldmethod == "diff")
  vim.cmd("diffoff")
  pause(100)
  assert(vim.wo.foldmethod == "expr" and vim.wo.foldlevel ~= 99)

  -- Exercise the first editing burst before deferred fold initialization settles.
  vim.cmd("enew")
  api.nvim_buf_set_lines(0, 0, -1, false, { "prefix " })
  vim.bo.filetype = "lua"
  feed("A" .. string.rep("abcdefghij", 50) .. "<Esc>")
  pause(100)
  assert(api.nvim_get_current_line() == "prefix " .. string.rep("abcdefghij", 50))
  assert(vim.wo.foldlevel ~= 99)

  vim.cmd("enew!")
  api.nvim_buf_set_lines(0, 0, -1, false, { "outer", "  body", "  body", "last" })
  vim.bo.filetype = "unknown_folding_test"
  pause(100)
  assert(vim.wo.foldmethod == "indent")
  feed("zM")
  assert(vim.fn.foldclosed(2) == 2)
  api.nvim_win_set_cursor(0, { 2, 0 })
  pause(30)
  feed("zK")
  pause(60)
  local last_preview = vim.b.lsp_floating_preview
  assert(last_preview and api.nvim_win_is_valid(last_preview))
  fold.disable()
  assert(not api.nvim_win_is_valid(last_preview))
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    local worker = coroutine.create(check)
    local function advance()
      local ok, delay = coroutine.resume(worker)
      if not ok or coroutine.status(worker) == "dead" then
        local message = ok
            and "folding TUI: native keys, zS/zK, preview focus, splits, diff, first insert and cleanup passed"
          or debug.traceback(worker, tostring(delay))
        vim.fn.writefile(vim.split(message, "\n", { plain = true }), vim.env.NVIM_LAZY_RESULT)
        vim.cmd(ok and "qa!" or "cquit 1")
      else
        vim.defer_fn(advance, delay)
      end
    end
    vim.defer_fn(advance, 100)
  end,
})
