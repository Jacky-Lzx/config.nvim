local M = {}

local icons = { [1] = "", [2] = "", [3] = "", [4] = "󰌶" }
local function prefix(diagnostic)
  return icons[diagnostic.severity] or diagnostic.message
end
local text = { spacing = 4, prefix = prefix }
local compact = {
  spacing = 0,
  prefix = prefix,
  format = function()
    return ""
  end,
}

local toggles = {
  {
    key = "<leader>tV",
    opts = {
      id = "virtual_lines",
      name = "Diagnostic virtual lines",
      get = function()
        return not not vim.diagnostic.config().virtual_lines
      end,
      set = function(state)
        vim.diagnostic.config({ virtual_lines = state and { current_line = true } or false })
      end,
    },
  },
  {
    key = "<leader>tv",
    opts = {
      id = "virtual_text",
      name = "Diagnostic text",
      get = function()
        local current = vim.diagnostic.config().virtual_text
        return type(current) == "table" and current.format == text.format
      end,
      set = function(state)
        vim.diagnostic.config({ virtual_text = state and text or compact })
      end,
    },
  },
}

function M.setup_toggles()
  -- Inspect the loaded module so diagnostics never forces Snacks to load.
  local snacks = package.loaded.snacks
  if snacks then
    snacks.toggle.diagnostics():map("<leader>td")
  else
    vim.keymap.set("n", "<leader>td", function()
      vim.diagnostic.enable(not vim.diagnostic.is_enabled())
    end, { desc = "Toggle diagnostics" })
  end

  for _, toggle in ipairs(toggles) do
    if snacks then
      snacks.toggle.new(toggle.opts):map(toggle.key)
    else
      vim.keymap.set("n", toggle.key, function()
        toggle.opts.set(not toggle.opts.get())
      end, { desc = "Toggle " .. toggle.opts.name })
    end
  end
end

function M.setup()
  vim.diagnostic.config({
    underline = false,
    signs = { text = icons },
    update_in_insert = false,
    severity_sort = true,
    virtual_text = text,
    virtual_lines = false,
    float = { border = "rounded" },
  })

  M.setup_toggles()
end

return M
