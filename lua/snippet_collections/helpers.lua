local M = {}

function M.define(trigger, description, body, options)
  return vim.tbl_extend("force", { trigger = trigger, description = description, body = body }, options or {})
end

function M.line_begin(ctx, match)
  local before = ctx.before or ""
  return before:sub(1, match and match.start_col or ctx.start_col or #before):match("^%s*$") ~= nil
end

return M
