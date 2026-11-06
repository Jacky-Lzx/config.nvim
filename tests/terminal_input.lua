-- Observe consumption of the actual typed keys before asserting their result.
-- An appended escape-sequence sentinel can merge with a preceding Escape key.
return function(input, check, complete)
  local expected, received, done = input, "", false
  local offset = 1
  local ns = vim.api.nvim_create_namespace("config-test-terminal-input")
  local function finish(err)
    if done then
      return
    end
    done = true
    vim.on_key(nil, ns)
    complete(err)
  end
  vim.on_key(function(_, typed)
    if typed == "" or done then
      return
    end
    typed = typed:gsub(vim.keycode("<BS>"), "\127")
    received = received .. typed
    -- Mapping replay may repeat prefixes, notably named registers.
    for index = 1, #typed do
      if typed:sub(index, index) == expected:sub(offset, offset) then
        offset = offset + 1
      end
    end
    if offset > #expected then
      vim.on_key(nil, ns)
      dofile(vim.env.NVIM_CONFIG_ROOT .. "/tests/await_state.lua")("terminal result", check, finish)
    end
  end, ns)
  vim.defer_fn(function()
    if not done then
      finish(
        "Terminal input/result timed out: expected "
          .. vim.fn.keytrans(expected)
          .. ", consumed "
          .. vim.fn.keytrans(received)
      )
    end
  end, 5000)
end
