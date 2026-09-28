local M = {}

function M.code_sources()
  local sources = { "lsp", "path" }
  if require("blink.cmp.config").sources.providers.lazydev then
    table.insert(sources, 1, "lazydev")
  end
  return sources
end

return M
