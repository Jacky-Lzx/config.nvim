-- Wait for the asserted rendered/editor state after a terminal input barrier.
return function(label, check, complete)
  local deadline = vim.uv.hrtime() + 2e9
  local function attempt()
    local ok, err = xpcall(check, debug.traceback)
    if ok then
      complete()
    elseif vim.uv.hrtime() >= deadline then
      complete(label .. ": " .. err)
    else
      vim.defer_fn(attempt, 10)
    end
  end
  vim.schedule(attempt)
end
