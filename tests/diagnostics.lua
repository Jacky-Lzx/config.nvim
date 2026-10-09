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
print("Diagnostic defaults, fallback mappings and Snacks toggle checks passed")
