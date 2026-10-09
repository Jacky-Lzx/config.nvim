local M = {}

function M.sources(config)
  if not vim.b.blink_sources then
    vim.b.blink_sources = vim.deepcopy(config.default)
  end
  return vim.b.blink_sources
end

function M.code_sources(config)
  local sources = { "lsp", "path" }
  if config.providers.lazydev then
    table.insert(sources, 1, "lazydev")
  end
  return sources
end

function M.cycle(config, direction)
  local choices = { M.sources(config), { "buffer" }, { "snippets" }, M.code_sources(config) }
  local index = vim.b.blink_cmp_provider_index or (direction == 1 and 1 or #choices + 1)
  index = (index - 1 + direction) % #choices + 1
  vim.b.blink_cmp_provider_index = index
  return choices[index]
end

function M.toggle_source(config, name)
  local sources = M.sources(config)
  if vim.list_contains(sources, name) then
    sources = vim.tbl_filter(function(source)
      return source ~= name
    end, sources)
  else
    table.insert(sources, 1, name)
  end
  vim.b.blink_sources = sources
  return sources
end

return M
