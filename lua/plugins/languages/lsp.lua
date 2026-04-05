local signs = { Error = "", Warn = "", Hint = "󰌶", Info = "" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

local virtual_text_config_enabled = {
  spacing = 4,
  prefix = function(diagnostic)
    if diagnostic.severity == vim.diagnostic.severity.ERROR then
      return signs.Error
    elseif diagnostic.severity == vim.diagnostic.severity.WARN then
      return signs.Warn
    elseif diagnostic.severity == vim.diagnostic.severity.INFO then
      return signs.Info
    elseif diagnostic.severity == vim.diagnostic.severity.HINT then
      return signs.Hint
    end
    return diagnostic.message
  end,
}

local virtual_text_config_disabled = {
  spacing = 0,
  format = function(_)
    return ""
  end,
  prefix = function(diagnostic)
    if diagnostic.severity == vim.diagnostic.severity.ERROR then
      return signs.Error
    elseif diagnostic.severity == vim.diagnostic.severity.WARN then
      return signs.Warn
    elseif diagnostic.severity == vim.diagnostic.severity.INFO then
      return signs.Info
    elseif diagnostic.severity == vim.diagnostic.severity.HINT then
      return signs.Hint
    end
    return diagnostic.message
  end,
}

local signs_config = {
  text = {
    [vim.diagnostic.severity.ERROR] = signs.Error,
    [vim.diagnostic.severity.WARN] = signs.Warn,
    [vim.diagnostic.severity.INFO] = signs.Info,
    [vim.diagnostic.severity.HINT] = signs.Hint,
  },
  severity = {
    vim.diagnostic.severity.ERROR,
    vim.diagnostic.severity.WARN,
    vim.diagnostic.severity.INFO,
    vim.diagnostic.severity.HINT,
  },
}

local virtual_lines_config = { current_line = true }
vim.diagnostic.config({
  underline = false,
  signs = signs_config,
  update_in_insert = false,
  virtual_text = virtual_text_config_enabled,
  virtual_lines = false,
  severity_sort = true,
  float = {
    border = "rounded",
  },
})

local snacks = require("snacks")

snacks.toggle.diagnostics():map("<leader>td")
snacks.toggle
  .new({
    id = "virtual_lines",
    name = "Virtual lines",
    get = function()
      return not not vim.diagnostic.config().virtual_lines
    end,
    set = function(state)
      if state then
        vim.diagnostic.config({ virtual_lines = virtual_lines_config })
      else
        vim.diagnostic.config({ virtual_lines = false })
      end
    end,
  })
  :map("<leader>tV")
snacks.toggle
  .new({
    id = "virtual_text",
    name = "Virtual text",
    get = function()
      return vim.diagnostic.config().virtual_text.format == virtual_text_config_enabled.format
    end,
    set = function(state)
      if state then
        vim.diagnostic.config({ virtual_text = virtual_text_config_enabled })
      else
        vim.diagnostic.config({ virtual_text = virtual_text_config_disabled })
      end
    end,
  })
  :map("<leader>tv")

return {}
