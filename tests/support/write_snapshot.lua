-- Publish complete UTF-8 JSON for an external reader polling between UI frames.
return function(path, state)
  local temporary = path .. ".tmp"
  assert(vim.fn.writefile({ vim.json.encode(state) }, temporary) == 0)
  assert(vim.uv.fs_rename(temporary, path))
end
