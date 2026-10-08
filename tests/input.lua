local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), "xt", false)
end

local function check()
  local source = require("config.pairing").source()
  local plugins = require("lazy.core.config").plugins
  if vim.env.NVIM_TEST_PAIRING == "missing" then
    assert(not source.available)
  end
  assert((plugins["pairs.nvim"] ~= nil) == source.available)
  assert(not plugins["nvim-autopairs"] and not plugins["mini.pairs"])

  -- CmdlineEnter can load completion before the first InsertEnter.
  feed(":<Esc>")
  assert(plugins["blink.cmp"]._.loaded)
  -- Blink initializes its matcher asynchronously after loading. Let setup finish
  -- before the next physical input, as the interactive event loop does.
  assert(
    vim.wait(1000, function()
      return package.loaded["blink.cmp.completion"] ~= nil
    end, 10),
    "Completion did not finish setup"
  )
  if source.available then
    assert(require("pairs").status().initialized)
  else
    assert(not package.loaded.pairs)
  end

  local function input(keys, expected)
    vim.cmd("enew!")
    vim.bo.filetype = "lua"
    vim.bo.autoindent = true
    vim.bo.expandtab = true
    vim.bo.shiftwidth = 2
    vim.bo.indentexpr = ""
    vim.bo.smartindent = false
    vim.bo.cindent = false
    feed("i" .. keys .. "<Esc>")
    local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(vim.deep_equal(actual, expected), vim.inspect({ keys = keys, actual = actual, expected = expected }))
  end
  if source.available then
    input("(", { "()" })
    input("(<BS>", { "" })
    input("(<CR>x", { "(", "  x", ")" })
    input("don'", { "don'" })
  else
    input("(", { "(" })
    input("(<CR>x", { "(", "x" })
  end
  input("x<CR>y", { "x", "y" })
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end

vim.defer_fn(function()
  local ok, err = xpcall(check, debug.traceback)
  if ok then
    print("Actual input checks passed (" .. (vim.env.NVIM_TEST_PAIRING or "local") .. ")")
    vim.cmd("quitall!")
  else
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  end
end, 100)
