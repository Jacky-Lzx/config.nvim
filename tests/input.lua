local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), "xt", false)
end

local function check()
  local source = require("features.pairing").source()
  local plugins = require("lazy.core.config").plugins
  if vim.env.NVIM_TEST_PAIRING == "missing" then
    assert(not source.available)
  end
  assert((plugins["pairs.nvim"] ~= nil) == source.available)
  assert(not plugins["nvim-autopairs"] and not plugins["mini.pairs"])

  -- Health reporting shares source availability without initializing the plugin.
  local health, system = vim.health, vim.system
  local notices = {}
  vim.health = {}
  for _, level in ipairs({ "start", "info", "warn", "ok" }) do
    vim.health[level] = function(message)
      notices[#notices + 1] = { level = level, message = message }
    end
  end
  vim.system = function(argv, options)
    assert(source.available, "Missing pairing must not invoke Git")
    assert(vim.deep_equal(argv, { "git", "-C", source.dir, "rev-parse", "HEAD" }) and options.text)
    return {
      wait = function()
        return { code = 0, stdout = "fixture-revision\n" }
      end,
    }
  end
  require("features.pairing.health").check()
  vim.health, vim.system = health, system
  assert(notices[1].level == "start" and notices[1].message == "Pairing plugin")
  assert(notices[2].level == (source.available and "ok" or "warn"))
  assert(notices[2].message:find(source.dir, 1, true))
  assert(notices[3].message:find(source.available and "fixture-revision" or "NVIM_DEV_PLUGIN_ROOT", 1, true))
  assert(not package.loaded.pairs, "Health reporting loaded the pairing plugin")

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
    print("Actual input checks passed (" .. (vim.env.NVIM_TEST_PAIRING or "local") .. ")")
    vim.cmd("quitall!")
  else
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  end
end, 100)
