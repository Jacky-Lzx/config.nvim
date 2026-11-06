local M = {}

local names = { "error", "warn", "info", "hint" }
local labels = { "E", "W", "I", "H" }
local function icon(severity)
  local shared = package.loaded["theme_tools.icons"]
  if shared and names[severity] then
    return shared.get("diagnostic", names[severity])
  end
  return labels[severity] or ""
end
local function prefix(diagnostic)
  return (names[diagnostic.severity] and icon(diagnostic.severity) or diagnostic.message)
end
local function refresh_icons()
  local current = vim.diagnostic.config().signs
  local options = {}
  if current ~= false then
    local signs = type(current) == "table" and vim.deepcopy(current) or {}
    signs.text = {}
    for severity = 1, 4 do
      signs.text[severity] = icon(severity)
    end
    options.signs = signs
  end
  -- Re-show cached diagnostics so both native signs and virtual text update.
  vim.diagnostic.config(options)
  local ui = package.loaded.ui_tools
  local column = ui and ui.get_state("statuscolumn")
  if column and column.enabled then
    require("ui_tools.statuscolumn").refresh()
  end
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
  -- Native enable/hide updates signs without emitting DiagnosticChanged.
  local ui = package.loaded.ui_tools
  local column = ui and ui.get_state("statuscolumn")
  if column and column.enabled then
    require("ui_tools.statuscolumn").refresh()
  end
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
    signs = { text = {} },
    update_in_insert = false,
    severity_sort = true,
    virtual_text = text,
    virtual_lines = false,
    float = { border = "rounded" },
  })

  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("ConfigDiagnosticIcons", { clear = true }),
    pattern = { "ThemeToolsReady", "ThemeToolsIconsChanged" },
    callback = refresh_icons,
  })
  refresh_icons()

  vim.keymap.set("n", "<A-j>", function()
    jump(1)
  end, { desc = "Go to next diagnostic" })
  vim.keymap.set("n", "<A-k>", function()
    jump(-1)
  end, { desc = "Go to previous diagnostic" })

  vim.keymap.set("n", "<leader>td", function()
    M.set_enabled(not M.enabled())
    require("features.toggles").notify("Diagnostics", M.enabled())
  end, { desc = "Toggle diagnostics" })
  vim.keymap.set("n", "<leader>tV", function()
    M.set_virtual_lines(not M.virtual_lines_enabled())
    require("features.toggles").notify("Diagnostic virtual lines", M.virtual_lines_enabled())
  end, { desc = "Toggle Diagnostic virtual lines" })
  vim.keymap.set("n", "<leader>tv", function()
    M.set_virtual_text(not M.virtual_text_enabled())
    require("features.toggles").notify("Diagnostic text", M.virtual_text_enabled())
  end, { desc = "Toggle Diagnostic text" })
end

return M
