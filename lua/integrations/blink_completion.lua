local M = {}

function M.cycle(cmp, direction)
  local config = require("blink.cmp.config").sources
  local sources = require("features.completion").cycle(config, direction)
  return cmp.show({ providers = sources })
end

function M.toggle_source(cmp, name)
  local config = require("blink.cmp.config").sources
  local sources = require("features.completion").toggle_source(config, name)
  return cmp.show({ providers = sources })
end

return M
