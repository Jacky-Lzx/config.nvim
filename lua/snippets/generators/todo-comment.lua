local s = require("luasnip.nodes.snippet").S
local sn = require("luasnip.nodes.snippet").SN
local t = require("luasnip.nodes.textNode").T
local i = require("luasnip.nodes.insertNode").I
local f = require("luasnip.nodes.functionNode").F
local c = require("luasnip.nodes.choiceNode").C
local fmta = require("luasnip.extras.fmt").fmta

_G.luasnip = {}
_G.luasnip.vars = {
  username = "lzx",
}

--- Options for marks to be used in a TODO comment
local marks = {
  order = { "date_signature", "date", "none" },
  date_signature = function()
    return i(1, "<" .. os.date("%Y.%m.%d") .. ", " .. _G.luasnip.vars.username .. ">")
  end,
  date = function()
    return i(1, "<" .. os.date("%Y.%m.%d") .. ">")
  end,
  none = function()
    return t("")
  end,
}

--- Get the comment string {beg,end} table
---@return table comment_strings {begcstring, endcstring}
local get_cstring = function()
  local cursor = vim.api.nvim_win_get_cursor(0) -- get the current cursor position
  local cstring = require("mini.comment").get_commentstring({ cursor[1], cursor[2] + 1 })

  local left, right = cstring:match("^(.*)%%s(.*)$")
  left = vim.trim(left)
  right = vim.trim(right)

  -- create a `{left, right}` table for it
  return { left, right }
end

local todo_snippet_nodes = function(aliases)
  local aliases_node = nil
  if #aliases == 1 then
    aliases_node = sn(1, t(aliases[1])) -- if we have only one alias, we do not need a choice-node, so we can just return a text-node
  else
    aliases_node = c(
      1,
      vim.tbl_map(function(alias)
        return i(nil, alias) -- if we have more than one alias, we generate a choice-node with the aliases as choices
      end, aliases)
    )
  end

  local sigmark_order = marks.order -- get the order of the marks from the `marks` table
  local sigmark_nodes = {} -- choices for [comment-mark]
  for _, mark in ipairs(sigmark_order) do
    table.insert(sigmark_nodes, marks[mark]())
  end

  -- format them into the actual snippet
  local comment_node = fmta("<> <>: <> <> <>", {
    f(function()
      return get_cstring()[1] -- get <comment-string[1]>
    end),
    aliases_node,
    i(3), -- {comment-text}
    c(2, sigmark_nodes), -- [comment-mark]
    f(function()
      return get_cstring()[2] -- get <comment-string[2]>
    end),
  })
  return comment_node
end

--- Generate a TODO comment snippet with an automatic description and docstring
---@param context table merged with the generated context table `trig` must be specified
---@param aliases string[]|string of aliases for the todo comment (ex.: {FIX, ISSUE, FIXIT, BUG})
---@param opts table merged with the snippet opts table
local todo_snippet = function(context, aliases, opts)
  opts = opts or {}
  aliases = type(aliases) == "string" and { aliases } or aliases -- if we do not have aliases, be smart about the function parameters
  context = context or {}
  if not context.trig then
    return error("context doesn't include a `trig` key which is mandatory", 2) -- all we need from the context is the trigger
  end
  local alias_string = table.concat(aliases, "|") -- `choice_node` documentation
  context.name = context.name or (alias_string .. " comment") -- generate the `name` of the snippet if not defined
  context.dscr = context.dscr or (alias_string .. " comment with a signature-mark") -- generate the `dscr` if not defined
  context.docstring = context.docstring or (" {1:" .. alias_string .. "}: {3} <{2:mark}>{0} ") -- generate the `docstring` if not defined
  local comment_node = todo_snippet_nodes(aliases) -- nodes from the previously defined function for their generation
  return s(context, comment_node, opts) -- the final todo-snippet constructed from our parameters
end

local todo_snippet_specs = {
  { { trig = "todo" }, "TODO" },
  { { trig = "fix" }, { "FIX", "BUG", "ISSUE", "FIXIT" } },
  { { trig = "hack" }, "HACK" },
  { { trig = "warn" }, { "WARN", "WARNING", "XXX" } },
  { { trig = "perf" }, { "PERF", "PERFORMANCE", "OPTIM", "OPTIMIZE" } },
  { { trig = "note" }, { "NOTE", "INFO" } },
}

local M = {}

function M.generate_todo_comment_snippets()
  local snippets = {}
  for _, v in ipairs(todo_snippet_specs) do
    table.insert(snippets, todo_snippet(v[1], v[2], v[3]))
  end
  return snippets
end

return M
