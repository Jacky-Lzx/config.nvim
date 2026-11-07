-- Publish complete UTF-8 JSON for an external reader polling between UI frames.
return function(path, state)
  if state.screen then
    local lines = type(state.screen) == "table" and state.screen or vim.split(state.screen, "\n", { plain = true })
    vim.fn.writefile(lines, (vim.env.NVIM_TEST_ARTIFACT_DIR or vim.fs.dirname(path)) .. "/screen.txt")
  end
  local temporary = path .. ".tmp"
  assert(vim.fn.writefile({ vim.json.encode(state) }, temporary) == 0)
  assert(vim.uv.fs_rename(temporary, path))
end
