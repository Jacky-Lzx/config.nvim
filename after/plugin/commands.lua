vim.schedule(function()
  vim.api.nvim_create_user_command("Titlecase", function()
    -- 1. Selection Range
    local s_start = vim.fn.getpos("'<")
    local s_end = vim.fn.getpos("'>")
    local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)

    -- 2. Smart Lookup Table
    local small_words = {
      ["a"] = true,
      ["an"] = true,
      ["the"] = true,
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

    -- 3. Apply Transformation
    if #lines > 0 then
      -- Process first line (handling partial selection)
      local prefix = string.sub(lines[1], 1, s_start[3] - 1)
      local target = string.sub(lines[1], s_start[3])
      lines[1] = prefix .. to_smart_title(target)

      -- Process middle lines
      for i = 2, #lines - 1 do
        lines[i] = to_smart_title(lines[i])
      end

      -- Process last line (handling partial selection)
      if #lines > 1 then
        local suffix = string.sub(lines[#lines], s_end[3] + 1)
        local last_target = string.sub(lines[#lines], 1, s_end[3])
        lines[#lines] = to_smart_title(last_target) .. suffix
      end

      vim.api.nvim_buf_set_lines(0, s_start[2] - 1, s_end[2], false, lines)
    end
  end, { range = true })

  vim.api.nvim_create_user_command("ConvertTabToSpace", "%s/\t/  /g", {})
end)
