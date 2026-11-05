local s = require("snippet_tools")
local M = {}

-- Templates contain literal TeX and <> node slots; formatting belongs to the engine.
M.format = s.fmta

function M.define(trigger, description, body, options)
  return vim.tbl_extend("force", { trigger = trigger, description = description, body = body }, options or {})
end

function M.condition(name)
  return function(ctx)
    local key = "tex_" .. name
    if ctx.cache[key] == nil then
      ctx.cache[key] = require("snippets.tex.utils.math_conditions").fn[name]()
    end
    return ctx.cache[key]
  end
end
M.math = M.condition("in_math")
M.latex = M.condition("is_latex")
M.beamer = M.condition("in_beamer")
M.bullets = M.condition("in_bullets")
M.align = M.condition("in_align")
M.figure = M.condition("in_figure")
function M.not_math(ctx)
  return not M.math(ctx)
end
function M.line_begin(ctx, match)
  return ctx.before:sub(1, match and match.start_col or #ctx.before):match("^%s*$") ~= nil
end
function M.selected(ctx)
  return ctx.selected_text ~= nil and ctx.selected_text ~= ""
end
function M.inline_math(ctx)
  return M.selected(ctx) or M.not_math(ctx)
end
function M.display_math(ctx, match)
  return (M.line_begin(ctx, match) and M.selected(ctx)) or M.not_math(ctx)
end

function M.content(index, trim, default)
  return s.d(index, function(_, ctx)
    local text = ctx.selected_text or ""
    if text == "" then
      return s.i(1, default or "")
    end
    if trim ~= false and not text:find("\n", 1, true) then
      text = vim.trim(text)
    end
    return s.t(text)
  end)
end
function M.environment(name, argument)
  return M.format(
    [[
    \begin{<>}<>
      <>
    \end{<>}
  ]],
    { s.t(name), argument or s.t(""), s.i(0), s.t(name) }
  )
end
function M.label(args)
  return args[1]:gsub("%.[^.]*$", ""):gsub("_", "-")
end

-- Match the same word characters as the previous LuaSnip postfix definitions.
function M.postfix(trigger, description, left, right, fraction)
  return M.define("([%w%.%_%-%\"']+)" .. vim.pesc(trigger), description, {
    s.d(1, function(_, ctx)
      local text = ctx.match.captures[1]
      if fraction then
        return M.format([[\frac{<>}{<>}]], { s.t(text), s.i(1) })
      end
      return { s.t(left .. text .. right) }
    end),
    s.i(0),
  }, {
    pattern = true,
    auto = true,
    word = false,
    priority = fraction and 2000 or 1000,
    condition = M.math,
    show_condition = M.math,
  })
end
return M
