local M = {}

function M.sources(config, ctx)
  local buf = ctx and ctx.bufnr or vim.api.nvim_get_current_buf()
  local explicit = vim.b[buf].completion_tools_sources
  if explicit then
    return explicit
  end
  return config.defaults and config.defaults(ctx) or vim.deepcopy(config.default)
end

function M.code_sources()
  return { "lsp", "path" }
end

function M.active_sources(config, ctx)
  local choices = { M.sources(config, ctx), { "buffer", "dictionary", "spell" }, { "snippets" }, M.code_sources() }
  local buf = ctx and ctx.bufnr or vim.api.nvim_get_current_buf()
  return choices[vim.b[buf].completion_tools_source_index or 1]
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
