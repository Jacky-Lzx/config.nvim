local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(require("utils.platform").dev_plugin_root() .. "/keymap-tools.nvim")
local spec = require("plugins.coding.format-tools")[1]
vim.opt.runtimepath:prepend(require("utils.platform").dev_plugin_root() .. "/" .. spec.id)
local F = require("format_tools")
spec.config({ opts = spec.opts })
assert(vim.fn.exists(":FormatToolsInfo") == 2)
assert(not package.loaded.conform, "Replaced formatter must not load")
local current = vim.api.nvim_get_current_buf()
local function sample(ft, extension, lines)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, vim.env.NVIM_TEST_TMP .. "/format-runtime." .. extension)
  vim.bo[buf].filetype, vim.bo[buf].expandtab, vim.bo[buf].shiftwidth = ft, true, 2
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return buf
end
local function save(buf)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent write")
  end)
  assert(vim.api.nvim_get_current_buf() == current, "Formatting changed the active buffer")
end
local lua = sample("lua", "lua", { "local value={a=1}", "return value" })
save(lua)
assert(F.status(lua).status == "done", vim.inspect(F.status(lua)))
assert(vim.api.nvim_buf_get_lines(lua, 0, 1, false)[1] == "local value = { a = 1 }")
local python = sample("python", "py", { "import sys", "import os", "x=1+2", "print(os.name,sys.version,x)" })
save(python)
assert(F.status(python).status == "done", vim.inspect(F.status(python)))
local result = vim.api.nvim_buf_get_lines(python, 0, -1, false)
assert(result[1] == "import os" and result[2] == "import sys")
assert(table.concat(result, "\n"):find("x = 1 + 2", 1, true))
local text = sample("text", "txt", { "keep   " })
vim.b[text].disable_autoformat = true
save(text)
assert(vim.api.nvim_buf_get_lines(text, 0, 1, false)[1] == "keep   ")
vim.b[text].disable_autoformat = nil
save(text)
assert(vim.api.nvim_buf_get_lines(text, 0, 1, false)[1] == "keep")
vim.api.nvim_buf_call(text, function()
  vim.cmd("silent undo")
end)
assert(vim.api.nvim_buf_get_lines(text, 0, 1, false)[1] == "keep   ")
vim.g.enable_autoformat = false
save(text)
assert(vim.fn.readfile(vim.api.nvim_buf_get_name(text))[1] == "keep   ")
vim.g.enable_autoformat = true
save(text)
assert(vim.fn.readfile(vim.api.nvim_buf_get_name(text))[1] == "keep")
local large = sample("text", "large.txt", { string.rep("x", 1600000) .. "   " })
save(large)
assert(vim.api.nvim_buf_get_lines(large, 0, 1, false)[1]:sub(-3) == "   ", "Autoformat touched a growing large buffer")
local minified = sample("text", "minified.txt", { string.rep("x", 2000) .. "   " })
save(minified)
assert(vim.api.nvim_buf_get_lines(minified, 0, 1, false)[1]:sub(-3) == "   ", "Autoformat touched a minified buffer")
vim.b[minified].bigfile = true
vim.api.nvim_buf_set_lines(minified, 0, -1, false, { "small but protected   " })
save(minified)
assert(vim.fn.readfile(vim.api.nvim_buf_get_name(minified))[1] == "small but protected   ")
F.format({ bufnr = minified, async = false })
assert(
  vim.api.nvim_buf_get_lines(minified, 0, 1, false)[1] == "small but protected",
  "Explicit formatting must remain available"
)
print("Configured formatting: real StyLua/Ruff, save policy, fallback trim, undo and background buffer focus passed")
