local M = {}

function M.sources(config)
  if not vim.b.completion_tools_sources then
    vim.b.completion_tools_sources = vim.deepcopy(config.default)
  end
  return vim.b.completion_tools_sources
end

function M.code_sources()
  return { "lsp", "path" }
end

function M.active_sources(config)
  local choices = { M.sources(config), { "buffer" }, { "snippets" }, M.code_sources() }
  return choices[vim.b.completion_tools_source_index or 1]
end

function M.cycle(config, direction)
  local index = vim.b.completion_tools_source_index or 1
  vim.b.completion_tools_source_index = (index - 1 + direction) % 4 + 1
  return M.active_sources(config)
end

function M.toggle_source(config, name)
  assert(config.providers[name], "Completion source is not configured: " .. name)
  local sources = M.sources(config)
  if vim.list_contains(sources, name) then
    sources = vim.tbl_filter(function(source)
      return source ~= name
    end, sources)
  else
    table.insert(sources, 1, name)
  end
  vim.b.completion_tools_sources = sources
  vim.b.completion_tools_source_index = 1
  return sources
end

return M
