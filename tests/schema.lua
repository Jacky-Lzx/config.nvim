local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
local schema = require("languages.schema")

local function rejects(field, value, message)
  local ok, err = pcall(schema.validate, "fixture", { [field] = { python = value } })
  assert(not ok and tostring(err):find(message, 1, true), tostring(err))
end

rejects("linters", { ruff = true }, "expected a list")
rejects("linters", { [2] = "ruff" }, "expected a list")
rejects("linters", { "ruff", stop_after_first = true }, "expected a list")
rejects("linters", { false }, "expected a non-empty string")
rejects("formatters", { ruff = true }, "unknown formatter option")
rejects("formatters", { [2] = "ruff" }, "contiguous formatter indices")
rejects("formatters", { [0] = "ruff" }, "positive integer indices")
rejects("formatters", { [1.5] = "ruff" }, "positive integer indices")
rejects("formatters", { "ruff", stop_after_first = "yes" }, "expected boolean")
rejects("formatters", { "ruff", quiet = 1 }, "expected boolean")
rejects("formatters", { "ruff", timeout_ms = -1 }, "non-negative integer")
rejects("formatters", { "ruff", timeout_ms = 1.5 }, "non-negative integer")
rejects("formatters", { "ruff", lsp_format = "typo" }, "invalid LSP formatting mode")
rejects("formatters", { "ruff", filter = true }, "expected function")

local valid = {
  formatters = {
    python = {
      "ruff_fix",
      "ruff_format",
      stop_after_first = false,
      quiet = true,
      timeout_ms = 500,
      lsp_format = "fallback",
      id = 1,
      name = "basedpyright",
      filter = function()
        return true
      end,
      formatting_options = { tabSize = 4 },
    },
    disabled = {},
    lsp_only = { lsp_format = "prefer" },
  },
  linters = { python = { "ruff" }, disabled = {} },
}
local original = vim.deepcopy(valid)
schema.validate("fixture", valid)
assert(vim.deep_equal(valid, original), "Validation must not mutate declarations")
assert(not package.loaded.lazy and not package.loaded.conform and not package.loaded.lint)
print("Language binding schema rejects malformed lists and formatter options")
