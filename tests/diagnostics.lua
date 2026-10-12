local root = assert(vim.env.NVIM_CONFIG_ROOT, "NVIM_CONFIG_ROOT is required")
vim.opt.runtimepath:prepend(root)
vim.g.mapleader = " "
package.preload.snacks = function()
  error("Diagnostics must not force Snacks to load")
end

local before = vim.deepcopy(vim.diagnostic.config())
local diagnostics = require("features.lsp.diagnostics")
local integration = require("integrations.snacks_diagnostics")
assert(vim.deep_equal(vim.diagnostic.config(), before), "Requiring diagnostics must not apply settings")
assert(vim.fn.maparg("<leader>td", "n") == "")
diagnostics.setup()
local defaults = vim.diagnostic.config()
assert(not defaults.underline and not defaults.update_in_insert and defaults.severity_sort)
assert(defaults.virtual_lines == false and defaults.virtual_text.spacing == 4)
assert(defaults.float.border == "rounded")
for _, severity in pairs(vim.diagnostic.severity) do
  if type(severity) == "number" then
    assert(defaults.virtual_text.prefix({ severity = severity }) == defaults.signs.text[severity])
  end
end
assert(defaults.virtual_text.prefix({ severity = 99, message = "fallback" }) == "fallback")

local function toggle(key)
  vim.fn.maparg(key, "n", false, true).callback()
end
toggle("<leader>td")
assert(not vim.diagnostic.is_enabled())
toggle("<leader>td")
assert(vim.diagnostic.is_enabled())
toggle("<leader>tV")
assert(vim.diagnostic.config().virtual_lines.current_line)
toggle("<leader>tV")
assert(vim.diagnostic.config().virtual_lines == false)
toggle("<leader>tv")
assert(vim.diagnostic.config().virtual_text.format({ message = "hidden" }) == "")
toggle("<leader>tv")
assert(vim.diagnostic.config().virtual_text.format == nil)
assert(vim.diagnostic.config().virtual_text.spacing == 4)
assert(not package.loaded.snacks)

-- Once Snacks is loaded, its toggles must preserve the current diagnostic state.
toggle("<leader>tV")
toggle("<leader>tv")
local toggles, mapped = {}, {}
local snacks = {
  toggle = {
    new = function(opts)
      toggles[opts.id] = opts
      return {
        map = function(_, key)
          mapped[key] = true
        end,
      }
    end,
  },
}
integration.setup(snacks)
assert(mapped["<leader>td"] and mapped["<leader>tV"] and mapped["<leader>tv"])
assert(toggles.diagnostics.get())
toggles.diagnostics.set(false)
assert(not diagnostics.enabled())
toggles.diagnostics.set(true)
assert(diagnostics.enabled())
assert(toggles.virtual_lines.get() and not toggles.virtual_text.get(), "Snacks reset the fallback toggle state")
toggles.virtual_lines.set(false)
assert(not toggles.virtual_lines.get())
toggles.virtual_lines.set(true)
assert(toggles.virtual_lines.get() and vim.diagnostic.config().virtual_lines.current_line)
toggles.virtual_text.set(true)
assert(toggles.virtual_text.get())
toggles.virtual_text.set(false)
assert(not toggles.virtual_text.get())
assert(vim.diagnostic.config().virtual_text.format({ message = "hidden" }) == "")
assert(not package.loaded.snacks, "The integration must use its injected Snacks instance")

-- Diagnostics from linters must be navigable without an attached LSP or mini.bracketed.
local buffer = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buffer)
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "one", "two", "three", "four", "five", "six" })
local namespace = vim.api.nvim_create_namespace("diagnostic-navigation-test")
vim.diagnostic.set(namespace, buffer, {
  { lnum = 1, col = 0, message = "first diagnostic", severity = vim.diagnostic.severity.WARN },
  { lnum = 3, col = 0, message = "second diagnostic", severity = vim.diagnostic.severity.ERROR },
})
vim.api.nvim_buf_set_lines(buffer, 0, 0, false, { "inserted", "inserted" })
vim.api.nvim_win_set_cursor(0, { 6, 0 })

local function navigate(keys, row, message)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      vim.api.nvim_win_close(win, true)
    end
  end
  local editing_window = vim.api.nvim_get_current_win()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
  assert(vim.api.nvim_win_get_cursor(editing_window)[1] == row, "Wrong diagnostic target for " .. keys)
  local float
  assert(
    vim.wait(1000, function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative ~= "" then
          float = win
          return true
        end
      end
      return false
    end),
    "Jump did not open a diagnostic float"
  )
  assert(vim.api.nvim_get_current_win() == editing_window, "Diagnostic float stole focus")
  local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(float), 0, -1, false)
  assert(table.concat(lines, "\n"):find(message, 1, true), "Float showed the wrong diagnostic")
end

navigate("<A-k>", 4, "first diagnostic")
navigate("<A-k>", 6, "second diagnostic")
navigate("<A-j>", 4, "first diagnostic")
-- Verify count prefixes after the producer refreshes positions following edits.
vim.diagnostic.set(namespace, buffer, {
  { lnum = 3, col = 0, message = "first diagnostic", severity = vim.diagnostic.severity.WARN },
  { lnum = 5, col = 0, message = "second diagnostic", severity = vim.diagnostic.severity.ERROR },
})
vim.api.nvim_win_set_cursor(0, { 1, 0 })
navigate("2<A-j>", 6, "second diagnostic")
assert(not package.loaded["mini.bracketed"], "Diagnostic navigation must not load mini.bracketed")
print("Diagnostic defaults, native navigation, floats and Snacks toggle checks passed")
