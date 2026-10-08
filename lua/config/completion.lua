local M = {}

function M.sources()
  if not vim.b.blink_sources then
    vim.b.blink_sources = vim.deepcopy(require("blink.cmp.config").sources.default)
  end
  return vim.b.blink_sources
end

function M.code_sources()
  local sources = { "lsp", "path" }
  if require("blink.cmp.config").sources.providers.lazydev then
    table.insert(sources, 1, "lazydev")
  end
  return sources
end

function M.cycle(cmp, direction)
  local choices = { M.sources(), { "buffer" }, { "snippets" }, M.code_sources() }
  local index = vim.b.blink_cmp_provider_index or (direction == 1 and 1 or #choices + 1)
  index = (index - 1 + direction) % #choices + 1
  vim.b.blink_cmp_provider_index = index
  return cmp.show({ providers = choices[index] })
end

function M.toggle_source(cmp, name)
  local sources = M.sources()
  if vim.list_contains(sources, name) then
    sources = vim.tbl_filter(function(source)
      return source ~= name
    end, sources)
  else
    table.insert(sources, 1, name)
  end
  vim.b.blink_sources = sources
  return cmp.show({ providers = sources })
end

return M
