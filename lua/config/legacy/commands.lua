-- Command callbacks receive line numbers, not the original range expression.
local visual_range = false
vim.api.nvim_create_autocmd("CmdlineLeave", {
  pattern = ":",
  callback = function()
    visual_range = not vim.v.event.abort and vim.fn.getcmdline():match("^%s*'<,'>%s*Titlecase%s*$") ~= nil
    vim.schedule(function()
      visual_range = false
    end)
  end,
})
vim.api.nvim_create_user_command("Titlecase", function(opts)
  local regions
  if visual_range then
    regions = vim.fn.getregionpos(vim.fn.getpos("'<"), vim.fn.getpos("'>"), {
      type = vim.fn.visualmode(),
      exclusive = vim.o.selection == "exclusive",
    })
  end
  visual_range = false
  local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)

  -- 2. Smart Lookup Table
  local small_words = {
    ["a"] = true,
    ["an"] = true,
    ["the"] = true,
    ["with"] = true,
    ["and"] = true,
    ["but"] = true,
    ["for"] = true,
    ["or"] = true,
    ["nor"] = true,
    ["on"] = true,
    ["in"] = true,
    ["at"] = true,
    ["to"] = true,
    ["by"] = true,
    ["of"] = true,
  }

  local function to_smart_title(str)
    local count = 0
    -- Find words
    return (
      str:gsub("(%a)([%w_']*)", function(first, rest)
        count = count + 1
        local word = (first .. rest):lower()

        -- Capitalize if it's the first word or NOT in the lookup table
        if count == 1 or not small_words[word] then
          return first:upper() .. rest:lower()
        else
          return word
        end
      end)
    )
  end

  for i, line in ipairs(lines) do
    local first, last = 1, #line
    if regions then
      local region = regions[i]
      first, last = region[1][3], region[2][3]
    end
    lines[i] = line:sub(1, first - 1) .. to_smart_title(line:sub(first, last)) .. line:sub(last + 1)
  end
  vim.api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, lines)
end, { range = true })
