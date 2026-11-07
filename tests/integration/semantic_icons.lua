local root = assert(vim.env.NVIM_CONFIG_ROOT)
vim.opt.rtp:prepend(root)
local dev = require("utils.platform").dev_plugin_root()
vim.opt.rtp:append(dev .. "/theme-tools.nvim")
vim.opt.rtp:append(dev .. "/ui-tools.nvim")
require("config.context").initialize({ profiles = {}, features = { tasks = true } })
local api = vim.api
local diagnostics = require("features.lsp.diagnostics")
diagnostics.setup()
api.nvim_buf_set_lines(0, 0, -1, false, { "source" })
local ns = api.nvim_create_namespace("ConfiguredSemanticIcons")
vim.diagnostic.set(ns, 0, { { lnum = 0, col = 0, severity = 1, message = "example issue" } })
local scans = 0
package.loaded.task_tools = {
  status = function()
    scans = scans + 1
    return { failure = 1, stopped = 1, success = 1, running = 1, stopping = 0 }
  end,
}
local bars = require("features.bars")
local sections = bars.sections()
sections.a, sections.b, sections.c, sections.y, sections.z = {}, { "diagnostics" }, {}, {}, {}
require("ui_tools").setup({ statusline = { globalstatus = true, icons = false, sections = sections } })
bars.setup()
local themes = require("theme_tools")
themes.setup({
  persist = false,
  catppuccin = false,
  dracula = false,
  default = "theme-tools-mocha",
  themes = { "theme-tools-mocha" },
  icons = { default = "devicons" },
})
local function status()
  vim.wait(80)
  return api.nvim_eval_statusline(vim.wo.statusline, { winid = 0, maxwidth = 240 }).str
end
local function decoration()
  local sign, text = "", ""
  for _, mark in ipairs(api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
    local details = mark[4]
    if details.sign_text then
      sign = sign .. vim.trim(details.sign_text)
    end
    for _, chunk in ipairs(details.virt_text or {}) do
      text = text .. chunk[1]
    end
  end
  return sign, text
end
for _, case in ipairs({
  { nil, "", " 1", "󰄬 1" },
  { "ascii", "E", "F 1", "O 1" },
  { "none", "", "failure 1", "success 1" },
}) do
  if case[1] then
    assert(themes.icons.set(case[1]))
  end
  local current = status()
  assert(current:find(case[3], 1, true) and current:find(case[4], 1, true), current)
  local expected_count = case[2] ~= "" and case[2] .. "1" or "E1"
  assert(current:find(expected_count, 1, true), current)
  assert(vim.diagnostic.config().signs.text[1] == case[2])
  local sign, text = decoration()
  assert(sign == case[2], vim.inspect({ case, sign }))
  assert(text:find("example issue", 1, true))
  if case[2] ~= "" then
    assert(text:find(case[2], 1, true))
  end
end
assert(scans == 1, "icon switches rescanned task providers: " .. scans)
assert(not package.loaded["nvim-web-devicons"], "semantic icons eagerly loaded a file-icon provider")
diagnostics.set_virtual_text(false)
vim.diagnostic.config({ signs = false })
assert(themes.icons.set("ascii"))
assert(not diagnostics.virtual_text_enabled(), "icon refresh reset the text toggle")
assert(vim.diagnostic.config().signs == false, "icon refresh reenabled disabled signs")
require("ui_tools").disable()
print("configured semantic icons: live signs/virtual text/counters, ASCII/none, task cache and toggles passed")
