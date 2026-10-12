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

local function jump(direction)
  vim.diagnostic.jump({
    count = direction * vim.v.count1,
    wrap = true,
    on_jump = function(diagnostic, bufnr)
      if not diagnostic then
        return
      end
      vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
    end,
  })
end

function M.enabled()
  return vim.diagnostic.is_enabled()
end

function M.set_enabled(state)
  vim.diagnostic.enable(state)
end

function M.virtual_lines_enabled()
  return not not vim.diagnostic.config().virtual_lines
end

function M.set_virtual_lines(state)
  vim.diagnostic.config({ virtual_lines = state and { current_line = true } or false })
end

function M.virtual_text_enabled()
  local current = vim.diagnostic.config().virtual_text
  return type(current) == "table" and current.format == text.format
end

function M.set_virtual_text(state)
  vim.diagnostic.config({ virtual_text = state and text or compact })
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

  vim.keymap.set("n", "<A-j>", function()
    jump(1)
  end, { desc = "Go to next diagnostic" })
  vim.keymap.set("n", "<A-k>", function()
    jump(-1)
  end, { desc = "Go to previous diagnostic" })

  vim.keymap.set("n", "<leader>td", function()
    M.set_enabled(not M.enabled())
  end, { desc = "Toggle diagnostics" })
  vim.keymap.set("n", "<leader>tV", function()
    M.set_virtual_lines(not M.virtual_lines_enabled())
  end, { desc = "Toggle Diagnostic virtual lines" })
  vim.keymap.set("n", "<leader>tv", function()
    M.set_virtual_text(not M.virtual_text_enabled())
  end, { desc = "Toggle Diagnostic text" })
end

return M
