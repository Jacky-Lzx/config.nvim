local M = {}

function M.setup(bufnr)
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

  map("<leader>lb", "<Cmd>TexToolsBuild<CR>", "Build LaTeX document")
  map("<localleader>lv", "<Cmd>TexToolsForwardSearch<CR>", "PDF forward search")
  require("keymap_tools").register("latex.build-on-save", {
    buf = bufnr,
    toggles = {
      {
        keys = "<localleader>la",
        name = "Build on save",
        get = function(ctx)
          local tex = package.loaded["tex-tools"]
          return tex and tex.build_on_save_enabled(ctx.buf)
        end,
      },
    },
  })
  -- The plugin publishes Plug endpoints; this configuration owns physical keys.
  for key, action in pairs({
    ["<localleader>lt"] = "Outline",
    ["<localleader>lc"] = "Clean",
    ["<localleader>lC"] = "CleanFull",
    ["<localleader>lo"] = "BuildOutput",
    ["<localleader>lq"] = "Log",
    ["<localleader>le"] = "Errors",
    ["<localleader>lk"] = "CancelBuild",
    ["<localleader>lK"] = "CancelAllBuilds",
    ["<localleader>lg"] = "BuildStatus",
    ["<localleader>ldm"] = "JumpMathDelimiter",
    ["<localleader>ldc"] = "ChangeMathDelimiters",
    ["<localleader>ldd"] = "UnwrapMathDelimiters",
    ["<localleader>ldt"] = "ToggleMathDelimiterSize",
    ["<localleader>lcr"] = "RenameCommand",
    ["<localleader>lcd"] = "UnwrapCommand",
    ["<localleader>lEd"] = "UnwrapEnvironment",
    ["<localleader>lf"] = "ToggleMathDelimiters",
    ["<localleader>lEr"] = "RenameEnvironment",
    ["<localleader>lEt"] = "ToggleEnvironmentStar",
    ["<localleader>lm"] = "JumpEnvironment",
    ["<localleader>ll"] = "Build",
    ["]t"] = "NextCell",
    ["[t"] = "PreviousCell",
    ["]]"] = "NextSection",
    ["[["] = "PreviousSection",
    ["]i"] = "NextItem",
    ["[i"] = "PreviousItem",
    ["]e"] = "NextEnvironment",
    ["[e"] = "PreviousEnvironment",
    ["]m"] = "NextMath",
    ["[m"] = "PreviousMath",
  }) do
    -- Preserve the selected motion/layout owner, as the old opt-in preset did.
    if vim.fn.maparg(key, "n") == "" then
      plug(key, action, action)
    end
  end
  plug("]]", "CloseDelimiter", "Close LaTeX delimiter", "i")
  plug("<localleader>lcs", "SurroundCommand", "Surround command", { "n", "x" })
  plug("<localleader>lEs", "SurroundEnvironment", "Surround environment", { "n", "x" })
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
