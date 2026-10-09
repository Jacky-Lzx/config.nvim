local M = {}

function M.setup()
  local create = vim.api.nvim_create_user_command
  for alias, command in pairs({ W = "write", Wq = "wq", Q = "quit" }) do
    create(alias, command, { desc = "Alias for :" .. command, force = true })
  end

  create("ConfigInfo", function()
    vim.print(require("config").info())
  end, { desc = "Show Neovim version and configuration paths", force = true })

  create("ConvertTabToSpace", "%s/\t/  /g", {})

  create("KeyTest", function()
    print("Press any key...")
    local key = vim.fn.getcharstr()
    print("Key: " .. vim.fn.keytrans(key))
  end, {
    desc = "Show the next pressed key",
  })

  create("Titlecase", function(opts)
    local regions
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
end

return M
