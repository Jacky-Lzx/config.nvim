local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, wait, feed = editor.remote, editor.wait, editor.feed
editor.run(function()
  assert(remote("return not package.loaded.snacks"))
  for _, key in ipairs({ "gd", "gD", "gi", "gI", "gy", "gci", "gco", " ss", " sS" }) do
    assert(remote("return vim.fn.maparg(..., 'n', false, true).desc:find('[Snacks]', 1, true) ~= nil", key))
  end
  remote([[
    require("lazy").load({ plugins = { "snacks.nvim" } })
    _G.config_picker = require("snacks").picker({
      items = { { text = "alpha" }, { text = "beta" }, { text = "gamma" } },
      format = "text", preview = "none",
      confirm = function(picker, item) vim.g.config_picker_chosen = item.text; picker:close() end,
    })
  ]])
  wait("return _G.config_picker.list:count() == 3 and vim.fn.mode() == 'i'")
  assert(
    remote("return _G.config_picker.opts.layout.reverse and _G.config_picker.opts.layout.layout.box == 'vertical'")
  )
  assert(remote("return not require('snacks').config.dashboard.enabled and not require('snacks').config.image.enabled"))
  local start = remote("return _G.config_picker.list.cursor")
  feed("<A-j>")
  assert(remote("return _G.config_picker.list.cursor") ~= start)
  feed("<A-k>")
  assert(remote("return _G.config_picker.list.cursor") == start)
  remote("_G.config_picker.list:view(2)")
  local selected = remote("return _G.config_picker:current().text")
  feed("<Tab>")
  assert(remote("return #_G.config_picker:selected() == 1 and _G.config_picker.list.cursor == 1"))
  assert(remote("return _G.config_picker:selected()[1].text") == selected)
  feed("<S-Tab>")
  assert(remote("return #_G.config_picker:selected() == 2 and _G.config_picker.list.cursor == 2"))
  feed("beta")
  wait("return _G.config_picker.list:count() == 1 and _G.config_picker:current().text == 'beta'")
  feed("<CR>")
  wait("return vim.g.config_picker_chosen == 'beta' and _G.config_picker.closed")
  remote(
    "vim.ui.select({ 'one', 'two' }, { prompt = 'Select a value' }, function(item) vim.g.config_select_chosen = item end)"
  )
  wait("return #require('snacks').picker.get() == 1 and vim.fn.mode() == 'i'")
  feed("two")
  wait(
    "local p = require('snacks').picker.get()[1]; return p and p.list:count() == 1 and p:current().text:find('two', 1, true) ~= nil"
  )
  feed("<CR>")
  wait("return vim.g.config_select_chosen == 'two'")
end, "Picker checks: mappings, layout, filtering, navigation, selection and confirmation passed")
