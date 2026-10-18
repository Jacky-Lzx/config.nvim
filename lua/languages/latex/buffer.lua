local M = {}

function M.setup(bufnr)
  require("utils.latex_highlighting").attach(bufnr)
  vim.keymap.set("v", "<M-m>", 'c\\( <c-r>" \\)', { buffer = bufnr })
  vim.keymap.set("i", "<M-m>", "\\(  \\)<esc>hhi", { buffer = bufnr })

  local function map(key, action, description, modes)
    vim.keymap.set(modes or "n", key, action, { buffer = bufnr, remap = true, desc = description })
  end
  local function plug(key, action, description, modes)
    map(key, "<Plug>(TexTools" .. action .. ")", description, modes)
  end
  require("which-key").add({
    { "<localleader>l", group = "LaTeX", buffer = bufnr },
    { "<localleader>l", group = "LaTeX", buffer = bufnr, mode = "i" },
  })
  for _, entry in ipairs({
    { "<leader>lb", "Build", "Build" },
    { "<localleader>ll", "Build", "Build" },
    { "<localleader>lt", "Outline", "File outline" },
    { "<localleader>lT", "ProjectOutline", "Project outline" },
    { "<localleader>lq", "Log", "Compiler log" },
    { "<localleader>lv", "ForwardSearch", "PDF forward search" },
    { "<localleader>lk", "CancelBuild", "Cancel build" },
    { "<localleader>lK", "CancelAllBuilds", "Cancel all builds" },
    { "<localleader>le", "Errors", "Errors and warnings" },
    { "<localleader>lo", "BuildOutput", "Live compiler output" },
    { "<localleader>lg", "BuildStatus", "Build status" },
    { "<localleader>lc", "Clean", "Clean auxiliary files" },
    { "<localleader>lC", "CleanFull", "Clean all artifacts" },
    { "<localleader>lm", "JumpEnvironment", "Matching environment marker" },
    { "<localleader>lj", "InsertItem", "Insert list item", { "n", "i" } },
    { "dse", "UnwrapEnvironment", "Remove environment markers" },
    { "dsc", "UnwrapCommand", "Remove command wrapper" },
    { "dsd", "UnwrapMathDelimiters", "Remove math brackets" },
    { "cse", "RenameEnvironment", "Rename environment" },
    { "csc", "RenameCommand", "Rename command" },
    { "csd", "ChangeMathDelimiters", "Change math brackets" },
    { "tsf", "ToggleFraction", "Toggle fraction" },
    { "tsc", "ToggleCommandStar", "Toggle command star" },
    { "tse", "ToggleEnvironmentStar", "Toggle environment star" },
    { "ts$", "ToggleMathMode", "Toggle inline/display math" },
    { "tsd", "ToggleMathDelimiterSize", "Toggle math bracket sizing" },
    { "<F6>", "SurroundEnvironment", "Surround with environment", { "n", "x" } },
    { "<F7>", "SurroundCommand", "Surround with command", { "n", "x" } },
    { "<F8>", "ToggleMathDelimiterSize", "Toggle math bracket sizing" },
    { "]]", "CloseDelimiter", "Close delimiter", "i" },
    { "]]", "NextSection", "Next section" },
    { "][", "NextSection", "Next section" },
    { "[[", "PreviousSection", "Previous section" },
    { "]m", "NextEnvironment", "Next environment" },
    { "[m", "PreviousEnvironment", "Previous environment" },
    { "]n", "NextMath", "Next formula" },
    { "[n", "PreviousMath", "Previous formula" },
    { "]i", "NextItem", "Next list item" },
    { "[i", "PreviousItem", "Previous list item" },
    { "]t", "NextCell", "Next table cell" },
    { "[t", "PreviousCell", "Previous table cell" },
  }) do
    plug(unpack(entry))
  end
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
    local viewer = require("utils.platform").skim_displayline() and "skim" or "zathura"
    vim.cmd("TexToolsInverseSearch " .. viewer)
  end, "Show inverse-search setup")
end

return M
