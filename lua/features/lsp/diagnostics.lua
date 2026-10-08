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

  vim.keymap.set("n", "<leader>td", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  end, { desc = "Toggle diagnostics" })

  vim.keymap.set("n", "<leader>tV", function()
    vim.diagnostic.config({
      virtual_lines = not vim.diagnostic.config().virtual_lines and { current_line = true } or false,
    })
  end, { desc = "Toggle diagnostic virtual lines" })

  vim.keymap.set("n", "<leader>tv", function()
    local current = vim.diagnostic.config().virtual_text
    local enabled = type(current) == "table" and current.format == text.format
    vim.diagnostic.config({ virtual_text = enabled and compact or text })
  end, { desc = "Toggle diagnostic text" })
end

return M
