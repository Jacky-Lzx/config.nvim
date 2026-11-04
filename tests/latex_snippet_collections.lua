-- Definition parity and callback coverage without loading the full configuration.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(vim.fs.joinpath(require("utils.platform").dev_plugin_root(), "snippet-tools.nvim"))
vim.bo.filetype = "tex"
local native = dofile(root .. "/lua/snippet_collections/tex.lua")
local render = require("snippet_tools.render").render
local nodes = require("snippet_tools.nodes")
local context = {
  bufnr = 0,
  filetype = "tex",
  before = "",
  row = 0,
  col = 0,
  selected_text = "",
  match = { captures = { "x" }, start_col = 0 },
  cache = { tex_in_math = false, tex_is_latex = true, tex_in_beamer = false, tex_in_figure = false },
}
for _, entry in ipairs(native) do
  render(nodes.normalize(entry.body), { context = context })
end
assert(
  not package.loaded.luasnip and not package.loaded["luasnip.extras.conditions"],
  "Native collection loads LuaSnip"
)
local conditions = require("snippets.tex.utils.math_conditions")
assert(conditions.fn.is_latex())
assert(not package.loaded["luasnip.extras.conditions"], "Shared predicate eagerly loads LuaSnip")

vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/LuaSnip")
local ls = require("luasnip")
ls.setup({ enable_autosnippets = true })
require("luasnip.loaders.from_lua").load({ paths = { root .. "/lua/snippets" }, include = { "tex" } })
local function key(trigger, auto, postfix)
  return trigger .. "/" .. tostring(auto) .. "/" .. tostring(postfix)
end
local migrated, total = {}, 0
local prefix = "([%w%.%_%-%\"']+)"
for _, entry in ipairs(native) do
  local postfix = entry.pattern == true
  local trigger = postfix and entry.trigger:sub(#prefix + 1):gsub("%%(.)", "%1") or entry.trigger
  local id = key(trigger, entry.auto == true, postfix)
  migrated[id] = migrated[id] or {}
  table.insert(migrated[id], entry)
end
local mismatches = {}
for _, auto in ipairs({ false, true }) do
  for _, entry in ipairs(ls.get_snippets("tex", { type = auto and "autosnippets" or "snippets" })) do
    local postfix = (
      { vec = true, hat = true, bar = true, overline = true, rm = true, sr = true, cb = true, sq = true }
    )[entry.trigger] or (entry.trigger == "//" and entry.effective_priority == 2000) or false
    local id = key(entry.trigger, auto, postfix)
    local candidates = assert(migrated[id], "Missing migrated definition " .. id)
    local slot = 1
    for index, item in ipairs(candidates) do
      if item.description:match("^[^\n]+") == entry.description[1] then
        slot = index
        break
      end
    end
    local candidate = table.remove(candidates, slot)
    assert(candidate, "Missing duplicate " .. id)
    assert(
      candidate.priority == nil and entry.effective_priority == 1000 or candidate.priority == entry.effective_priority,
      id .. " priority"
    )
    assert((candidate.word ~= false) == entry.wordTrig, id .. " word boundary")
    if not postfix then
      local expected = table.concat(entry:copy():get_static_text(), "\n"):gsub("%$SELECT_RAW", "")
      local actual = render(nodes.normalize(candidate.body), { context = context }).text
      if expected ~= actual then
        mismatches[#mismatches + 1] = { id = id, expected = expected, actual = actual }
      end
    end
    total = total + 1
  end
end
for id, candidates in pairs(migrated) do
  assert(#candidates == 0, "Unexpected migrated definition " .. id)
end
if #mismatches > 0 then
  error(vim.inspect(mismatches))
end
print("LaTeX collection: " .. total .. " definitions matched; native callbacks render without LuaSnip")

local engine = require("snippet_tools")
engine.setup({ keymap = false, paths = { root .. "/lua/snippet_collections" } })
local before = #engine.available()
engine.reload()
assert(#engine.available() == before, "Reload duplicates definitions")
engine.reload()
assert(#engine.available() == before, "Repeated reload duplicates definitions")
print("LaTeX collection reload: stable definition count")
