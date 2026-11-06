local M = {}

function M.setup(bufnr)
  require("languages.latex.highlighting").attach(bufnr)

  local function map(key, action, description, modes)
    vim.keymap.set(modes or "n", key, action, { buffer = bufnr, remap = true, desc = description })
  end
  local function plug(key, action, description, modes)
    map(key, "<Plug>(TexTools" .. action .. ")", description, modes)
  end

  require("keymap_tools").register("latex", {
    buf = bufnr,
    modes = { "n", "x", "o" },
    groups = { { prefix = "<localleader>l", label = "LaTeX" } },
  })

  map("<localleader>lv", "<Cmd>TexToolsForwardSearch<CR>", "PDF forward search")
  for _, object in ipairs({
    { "e", "Environment" },
    { "c", "Command" },
    { "a", "Argument" },
    { "$", "Math" },
    { "d", "MathDelimiter" },
    { "i", "Item" },
    { "P", "Section" },
    { "t", "Cell" },
  }) do
    plug("a" .. object[1], "Around" .. object[2], "Around " .. object[2], { "x", "o" })
    plug("i" .. object[1], "Inside" .. object[2], "Inside " .. object[2], { "x", "o" })
  end
  for _, entry in ipairs({
    { "<localleader>li", "Info", "Project information" },
    { "<localleader>lV", "View", "Open PDF" },
    { "<localleader>ls", "Main select", "Select main document" },
    { "<localleader>lB", "Compiler toggle", "Switch compiler" },
    { "<localleader>la", "BuildOnSave toggle", "Toggle build on save" },
  }) do
    map(entry[1], "<Cmd>TexTools" .. entry[2] .. "<CR>", entry[3])
  end
  map("<localleader>lr", function()
    local viewer = require("tex-tools.viewer").detect().method
    vim.cmd("TexToolsInverseSearch " .. viewer)
  end, "Show inverse-search setup")
end

return M
