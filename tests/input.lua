local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), "xt", false)
end

local function check()
  local plugins = require("lazy.core.config").plugins
  local pairing = assert(plugins["pairs.nvim"])
  assert(pairing.url == "https://github.com/Jacky-Lzx/pairs.nvim.git")
  assert(pairing.dev == false and not pairing._.is_local)
  assert(pairing.dir == vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "pairs.nvim"))
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
  assert(require("pairs").status().initialized)
  local module = debug.getinfo(require("pairs").setup, "S").source
  assert(module == "@" .. pairing.dir .. "/lua/pairs/init.lua", "Pairing loaded from an unmanaged checkout")

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
  input("(", { "()" })
  input("(<BS>", { "" })
  input("(<CR>x", { "(", "  x", ")" })
  input("don'", { "don'" })
  input("x<CR>y", { "x", "y" })

  local completion = require("integrations.blink_completion")
  local behavior = require("features.completion")
  local config = require("blink.cmp.config").sources
  local defaults = vim.deepcopy(config.default)
  local shown
  local cmp = {
    show = function(opts)
      shown = opts.providers
    end,
  }
  vim.cmd("enew!")
  completion.cycle(cmp, 1)
  assert(vim.deep_equal(shown, { "buffer" }))
  completion.cycle(cmp, 1)
  assert(vim.deep_equal(shown, { "snippets" }))
  completion.cycle(cmp, 1)
  assert(vim.deep_equal(shown, behavior.code_sources(config)))
  completion.cycle(cmp, 1)
  assert(vim.deep_equal(shown, defaults))
  completion.toggle_source(cmp, "buffer")
  completion.toggle_source(cmp, "buffer")
  assert(vim.deep_equal(require("blink.cmp.config").sources.default, defaults), "Buffer toggle mutated global defaults")
  vim.cmd("enew!")
  assert(vim.deep_equal(behavior.sources(config), defaults), "Completion state leaked into another buffer")
  completion.cycle(cmp, -1)
  assert(vim.deep_equal(shown, behavior.code_sources(config)))
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end

vim.defer_fn(function()
  local ok, err = xpcall(check, debug.traceback)
  if ok then
    print("Actual input checks passed (GitHub-managed pairing)")
    vim.cmd("quitall!")
  else
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  end
end, 100)
