-- Compare native definitions against a frozen export of the pre-migration engine.
-- No LuaSnip checkout or runtime is needed by this test.
local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(require("utils.platform").dev_plugin_root() .. "/snippet-tools.nvim")
local fixture = vim.json.decode(table.concat(vim.fn.readfile(root .. "/tests/fixtures/snippets-legacy.json"), "\n"))
vim.api.nvim_buf_set_name(0, "/private/tmp/" .. fixture.filename)
local date = os.date
os.date = function(format, ...)
  if format == "%Y.%m.%d" then
    return fixture.date
  end
  if format == "%Y.%m.%d %H:%M:%S" then
    return fixture.datetime
  end
  return date(format, ...)
end
local engine = require("snippet_tools")
local render, nodes = require("snippet_tools.render").render, require("snippet_tools.nodes")
local prefix = "([%w%.%_%-%\"']+)"
local function key(trigger, auto, postfix)
  return trigger .. "/" .. tostring(auto) .. "/" .. tostring(postfix)
end
local count = 0
for ft, expected in pairs(fixture.filetypes) do
  vim.bo.filetype, vim.bo.commentstring = ft, "-- %s"
  local context = engine.context()
  context.match = { captures = { "x" }, start_col = 0 }
  context.cache = { tex_in_math = false, tex_is_latex = ft == "tex", tex_in_beamer = false, tex_in_figure = false }
  local actual = {}
  for _, entry in ipairs(dofile(root .. "/lua/snippet_collections/" .. ft .. ".lua")) do
    local postfix = ft == "tex" and entry.pattern == true
    local trigger = postfix and entry.trigger:sub(#prefix + 1):gsub("%%(.)", "%1") or entry.trigger
    local id = key(trigger, entry.auto == true, postfix)
    actual[id] = actual[id] or {}
    actual[id][#actual[id] + 1] = entry
  end
  for _, old in ipairs(expected) do
    local id = key(old.trigger, old.auto, old.postfix)
    local candidates = assert(actual[id], ft .. ": missing " .. id)
    local slot = 1
    for index, entry in ipairs(candidates) do
      if entry.description and entry.description:match("^[^\n]+") == old.description then
        slot = index
        break
      end
    end
    local entry = assert(table.remove(candidates, slot), ft .. ": missing duplicate " .. id)
    assert((entry.priority or 1000) == old.priority, ft .. ": priority " .. id)
    assert((entry.word ~= false) == old.word, ft .. ": word boundary " .. id)
    context.match.captures = ft == "markdown" and entry.pattern and { "3", "2" } or { "x" }
    local text = render(nodes.normalize(entry.body), { context = context }).text
    if old.text then
      assert(
        text == old.text,
        vim.inspect({ filetype = ft, trigger = old.trigger, expected = old.text, actual = text })
      )
    elseif ft == "lua" and old.trigger == "snippet" then
      assert(
        text:find("trigger =", 1, true) and text:find("body =", 1, true),
        "Authoring template must produce native definitions"
      )
    end
    count = count + 1
  end
  for id, remaining in pairs(actual) do
    assert(#remaining == 0, ft .. ": unexpected " .. id)
  end
end
os.date = date
assert(count == 154, "Migration baseline definition count changed")
for name in pairs(package.loaded) do
  assert(not name:match("^luasnip"), "Unexpected legacy module: " .. name)
end
print("Native collections: " .. count .. " pre-migration definitions matched without a legacy engine")
