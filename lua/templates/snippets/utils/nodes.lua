local ls = require("luasnip")
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta

local M = {}

function M.visual_or_insert(_, parent, _, user_args)
  local ret = ""
  if user_args then
    ret = user_args
  end
  if #parent.snippet.env.SELECT_RAW == 1 then
    return sn(nil, t(vim.trim(parent.snippet.env.SELECT_RAW[1])))
  elseif #parent.snippet.env.SELECT_RAW > 1 then
    return sn(nil, t(parent.snippet.env.SELECT_RAW))
  else
    return sn(nil, i(1, ret))
  end
end

--- Modified from `https://github.com/L3MON4D3/LuaSnip/wiki/Cool-Snippets#smart-postfix-snippets`
function M.dynamic_postfix(_, parent, _, user_arg1, user_arg2)
  local capture = parent.snippet.env.POSTFIX_MATCH

  local text = ""
  if capture and #capture > 0 then
    text = capture
  else
    if #parent.snippet.env.SELECT_RAW > 0 then
      text = parent.snippet.env.SELECT_RAW
    end
  end

  return sn(nil, fmta([[<><><>]], { t(user_arg1), t(text), t(user_arg2) }))
end

function M.fmt_env(env_name, required_args)
  if not required_args then
    required_args = t("")
  end

  return fmta(
    [[
    \begin{<>}<>
      <>
    \end{<>}
  ]],
    { t(env_name), required_args, i(0), t(env_name) }
  )
end

return M
