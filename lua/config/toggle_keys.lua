-- Personal layout only. Feature owners provide actions and live state.
local M = {}
local entries = {
  { "spell", "tes", "Spelling" },
  { "wrap", "tew", "Wrap" },
  { "line_number", "ten", "Line Numbers" },
  { "relativenumber", "ter", "Relative Number" },
  { "conceallevel", "tec", "Conceal" },
  { "treesitter", "tet", "Treesitter Highlight" },
  { "background", "tub", "Dark Background" },
  { "indent", "tui", "Indent guides" },
  { "dim", "tud", "Scope dimming" },
  { "zen", "tuz", "Zen Mode" },
  { "zoom", "tum", "Zoom" },
  { "animate", "tua", "Animation" },
  { "scroll", "tus", "Scroll animation" },
  { "git_blame", "tgb", "Git line blame" },
  { "git_word_diff", "tgw", "Git word diff" },
  { "git_signs", "tgs", "Git signs" },
  { "git_overlay", "tgo", "Git diff overlay" },
  { "git_compare", "tgd", "Git diff view" },
  { "diagnostics", "tld", "Diagnostics" },
  { "diagnostic_text", "tlv", "Diagnostic text" },
  { "diagnostic_lines", "tll", "Diagnostic virtual lines" },
  { "inlay_hints", "tlh", "Inlay Hints" },
  { "autoformat", "tfa", "Auto format" },
  { "pairing", "tpe", "Pairing" },
  { "markdown_render", "tmr", "Render Markdown" },
  { "image_preview", "tia", "Automatic image preview" },
  { "tex_build_on_save", "txa", "Build on save" },
  { "running", "tdp", "Profiler" },
  { "highlighted", "tdh", "Profiler Highlights" },
  { "files.tree", "twf", "File tree" },
  { "tasks.list", "twt", "Task list" },
  -- { "tasks.terminal", "tws", "Terminal" },
  { "lsp.diagnostics", "twd", "Diagnostic overview" },
  { "lsp.locations", "twl", "Definitions/references" },
  { "lsp.loclist", "twc", "Location list" },
  { "lsp.quickfix", "twq", "Quickfix list" },
  { "lsp.outline", "two", "Outline" },
  { "dap.view", "twa", "Debugger view" },
}
local definitions = {}
for _, entry in ipairs(entries) do
  assert(not definitions[entry[1]], "Duplicate toggle layout ID: " .. entry[1])
  definitions[entry[1]] = { lhs = "<leader>" .. entry[2], name = entry[3] }
end
function M.get(id)
  return vim.deepcopy(assert(definitions[id], "Unknown toggle layout ID: " .. id))
end
function M.list()
  return vim.deepcopy(definitions)
end
function M.groups()
  local result = { { prefix = "<leader>t", label = "[Toggle]" } }
  for _, group in ipairs({
    { "e", "Editor" },
    { "u", "UI" },
    { "g", "Git" },
    { "l", "LSP / Diagnostics" },
    { "f", "Formatting" },
    { "p", "Pairs" },
    { "m", "Markdown" },
    { "i", "Images" },
    { "x", "TeX" },
    { "d", "Debug / Performance" },
    { "w", "Windows / Panels" },
  }) do
    result[#result + 1] = { prefix = "<leader>t" .. group[1], label = "[" .. group[2] .. "]" }
  end
  return result
end
return M
