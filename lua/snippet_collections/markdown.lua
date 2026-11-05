local s = require("snippet_tools")

local function content(index, default, trim)
  return s.d(index, function(_, ctx)
    local text = ctx.selected_text or ""
    if text ~= "" then
      if trim ~= false and not text:find("\n", 1, true) then
        text = vim.trim(text)
      end
      return s.t(text)
    end
    return s.i(1, default or "")
  end)
end
local function line_begin(ctx, match)
  return ctx.before:sub(1, match.start_col):match("^%s*$") ~= nil
end
local function outside_math(ctx)
  if ctx.selected_text and ctx.selected_text ~= "" then
    return true
  end
  if ctx.cache.in_math == nil then
    ctx.cache.in_math = require("snippet_collections.tex.context").fn.in_math()
  end
  return not ctx.cache.in_math
end
local function auto(trigger, body, condition)
  return {
    trigger = trigger,
    body = body,
    auto = true,
    hidden = true,
    pattern = trigger:find("%", 1, true) ~= nil,
    condition = condition,
  }
end
local function list(numbered)
  return {
    s.d(1, function(_, ctx)
      local result, count = {}, tonumber(ctx.match.captures[1])
      for index = 1, count do
        result[#result + 1] = s.t(numbered and index .. ". " or "- ")
        result[#result + 1] = s.i(index, tostring(index))
        if index < count then
          result[#result + 1] = s.t("\n")
        end
      end
      return result
    end),
    s.i(0),
  }
end

local details = {
  s.t("<details> <summary> "),
  s.i(1, "SUMMARY"),
  s.t(" </summary>\n  "),
  s.i(2, "DETAILS"),
  s.t("\n</details>"),
  s.i(0),
}
return {
  {
    trigger = "figure",
    description = "Image",
    preview = "![description](./Figures_markdown/file)",
    body = {
      s.t("!["),
      s.d(2, function(args)
        return s.i(1, args[1]:gsub("%.[^.]*$", ""):gsub("_", " "))
      end, { 1 }),
      s.t("](./Figures_markdown/"),
      s.i(1),
      s.t(")"),
      s.i(0),
    },
  },
  {
    trigger = "link",
    description = "Link",
    body = { s.t("["), s.i(1, "NAME"), s.t("]("), content(2, "LINK"), s.t(")"), s.i(0) },
  },
  {
    trigger = "code",
    description = "Code block",
    body = { s.t("```"), s.i(1), s.t("\n"), content(2), s.t("\n```"), s.i(0) },
  },
  { trigger = "bold", description = "Bold", body = { s.t("**"), content(1, "BOLD"), s.t("**"), s.i(0) } },
  { trigger = "italic", description = "Italics", body = { s.t("_"), content(1, "ITALIC"), s.t("_"), s.i(0) } },
  {
    trigger = "strike",
    description = "Strikethrough",
    body = { s.t("~~"), content(1, "STRIKETHROUGH"), s.t("~~"), s.i(0) },
  },
  { trigger = "quote", description = "Blockquote", body = { s.t("> "), content(1, "QUOTE"), s.i(0) } },
  {
    trigger = "emph",
    description = "Emphasis",
    priority = 2000,
    body = { s.t("**_"), content(1, "EMPH"), s.t("_**"), s.i(0) },
  },
  {
    trigger = "comment",
    description = "HTML comment",
    body = { s.t("<!-- "), content(1, "COMMENT"), s.t(" -->"), s.i(0) },
  },
  {
    trigger = "todo",
    description = "Checkbox",
    priority = 2000,
    body = { s.t("- "), s.c(1, { { s.t("["), s.i(1, " "), s.t("]") }, "[x]" }), s.t(" "), s.i(0) },
  },
  { trigger = "hide", description = "Hide details", body = details },
  { trigger = "detail", description = "Hide details", body = details },
  auto("#(%d+)%s", {
    s.d(1, function(_, ctx)
      local count = tonumber(ctx.match.captures[1])
      return { s.t(string.rep("#", math.max(1, count)) .. " "), s.i(1) }
    end),
    s.i(0),
  }, line_begin),
  auto("table(%d+)x(%d+)%s", {
    s.d(1, function(_, ctx)
      local rows, cols = tonumber(ctx.match.captures[1]), tonumber(ctx.match.captures[2])
      local result, index = {}, 0
      local function row(separator)
        result[#result + 1] = s.t("| ")
        for col = 1, cols do
          if separator then
            result[#result + 1] = s.t("-")
          else
            index = index + 1
            result[#result + 1] = s.i(index, tostring(index))
          end
          if col < cols then
            result[#result + 1] = s.t(" | ")
          end
        end
        result[#result + 1] = s.t(" |\n")
      end
      row(false)
      row(true)
      for _ = 3, rows + 1 do
        row(false)
      end
      return result
    end),
    s.i(0),
  }, line_begin),
  auto("item(%d+)%s", list(false), line_begin),
  auto("enum(%d+)%s", list(true), line_begin),
  auto("mk", { s.t("$"), content(1), s.t("$"), s.i(0) }, outside_math),
  auto("dm", { s.t("$$\n  "), content(1), s.t("\n$$"), s.i(0) }, outside_math),
}
