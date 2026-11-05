-- Compare the remaining migrated collections against the retained definitions.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(require("utils.platform").dev_plugin_root() .. "/snippet-tools.nvim")
local engine = require("snippet_tools")
local render = require("snippet_tools.render").render
local nodes = require("snippet_tools.nodes")
local native = {}
vim.api.nvim_buf_set_name(0, assert(vim.env.NVIM_TEST_TMP) .. "/example.v")
for _, ft in ipairs({ "all", "lua", "python", "rust", "typst", "verilog" }) do
  vim.bo.filetype = ft
  vim.bo.commentstring = "-- %s"
  local context = engine.context()
  native[ft] = {}
  for _, entry in ipairs(dofile(root .. "/lua/snippet_collections/" .. ft .. ".lua")) do
    native[ft][entry.trigger] = {
      text = render(nodes.normalize(entry.body), { context = context }).text,
      word = entry.word ~= false,
    }
  end
end
assert(not package.loaded.luasnip, "Rendering native collections loads LuaSnip")

vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/LuaSnip")
local ls = require("luasnip")
ls.setup({})
require("luasnip.loaders.from_lua").load({ paths = { root .. "/lua/snippets" }, include = vim.tbl_keys(native) })
local count = 0
for ft, definitions in pairs(native) do
  vim.bo.filetype, vim.bo.commentstring = ft, "-- %s"
  local entries = ls.get_snippets(ft)
  assert(#entries == vim.tbl_count(definitions), ft .. " definition count")
  for _, old in ipairs(entries) do
    local new = assert(definitions[old.trigger], ft .. ": missing " .. old.trigger)
    assert(new.word == old.wordTrig, ft .. ": word boundary " .. old.trigger)
    -- The snippet-authoring template intentionally writes native definitions now.
    if ft ~= "lua" or old.trigger ~= "snippet" then
      local expected = table.concat(old:copy():get_static_text(), "\n")
      assert(new.text == expected, vim.inspect({ ft = ft, trigger = old.trigger, old = expected, native = new.text }))
    end
    count = count + 1
  end
end
print("Native collections: " .. count .. " definitions matched retained triggers and defaults")
