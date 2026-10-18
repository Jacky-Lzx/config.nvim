local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), "xt", false)
end

local function check()
  local plugins = require("lazy.core.config").plugins
  local pairing = assert(plugins["pairs.nvim"])
  local dev_dir = vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "pairs.nvim")
  local local_pairing = vim.fn.isdirectory(dev_dir) == 1
  local expected_dir = local_pairing and dev_dir or vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "pairs.nvim")
  assert(pairing.url == "https://github.com/Jacky-Lzx/pairs.nvim.git")
  assert(pairing.dev == local_pairing, "Pairing did not select the expected development/fallback mode")
  assert((pairing._.is_local == true) == local_pairing)
  assert(pairing.dir == expected_dir, "Pairing did not select the expected checkout")
  assert(not plugins["nvim-autopairs"] and not plugins["mini.pairs"])
  assert(not plugins["mini.surround"] and not plugins["rainbow-delimiters.nvim"])

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
  assert(not pairing._.loaded, "Command-line completion must not load pairing")

  local function input(keys, expected, filetype)
    vim.cmd("enew!")
    vim.bo.filetype = filetype or "lua"
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
  assert(require("pairs").status().initialized)
  local module = debug.getinfo(require("pairs").setup, "S").source
  assert(module == "@" .. expected_dir .. "/lua/pairs/init.lua", "Pairing loaded from an unexpected checkout")
  input("(<BS>", { "" })
  input("(<CR>x", { "(", "  x", ")" })
  input("don'", { "don'" })
  input("x<CR>y", { "x", "y" })
  input("( ", { "(  )" })
  input("**hello**", { "**hello**" }, "markdown")
  input("**<BS>", { "" }, "markdown")
  input("~~hello~~", { "~~hello~~" }, "markdown")
  input("~~~<CR>x", { "~~~", "x", "~~~" }, "markdown")
  input("/*text*/", { "/*text*/" }, "cpp")
  input("/*<BS>", { "" }, "c")
  input("/*<CR>x", { "/*", "  x", "*/" }, "cpp")

  local function surround(lines, filetype, col, keys, expected)
    vim.cmd("enew!")
    vim.bo.filetype = filetype
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, col })
    local ok, parser = pcall(vim.treesitter.get_parser, 0)
    if ok then
      parser:parse()
    end
    feed(keys)
    local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(vim.deep_equal(actual, expected), vim.inspect({ keys = keys, actual = actual, expected = expected }))
  end
  surround({ "word" }, "markdown", 0, "saiw*", { "**word**" })
  surround({ "**word**" }, "markdown", 3, "sr*~", { "~~word~~" })
  surround({ "~~word~~" }, "markdown", 3, "sd~", { "word" })
  surround({ "word" }, "markdown", 0, "viwsa*", { "**word**" })
  surround({ "word" }, "cpp", 0, "saiwc", { "/*word*/" })
  surround({ 'local value = ("(word)")' }, "lua", 17, "sd)", { 'local value = "(word)"' })
  local status = require("pairs").status().surround
  assert(status.enabled and pairing.opts.surround.treesitter)
  assert(#status.conflicts == 0, vim.inspect(status.conflicts))
  assert(require("pairs.rainbow").status().enabled)

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
  return local_pairing and "local development pairing" or "GitHub fallback pairing"
end

vim.defer_fn(function()
  local ok, result = xpcall(check, debug.traceback)
  if ok then
    print("Actual input checks passed (" .. result .. ")")
    vim.cmd("quitall!")
  else
    io.stderr:write(result .. "\n")
    vim.cmd("cquit 1")
  end
end, 100)
