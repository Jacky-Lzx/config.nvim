local M = {}

function M.setup_actions(bufnr)
  require("keymap_tools").register("latex", {
    buf = bufnr,
    modes = { "n", "x", "o" },
    groups = { { prefix = "<localleader>l", label = "LaTeX" } },
  })

  for _, entry in ipairs({
    { "<leader>lb", "Build", "Build LaTeX document" },
    { "<localleader>ll", "Build", "Build LaTeX document" },
    { "<localleader>lk", "CancelBuild", "Cancel build" },
    { "<localleader>lK", "CancelAllBuilds", "Cancel all builds" },
    { "<localleader>lg", "BuildStatus", "Build status" },
    { "<localleader>lo", "BuildOutput", "Compiler output" },
    { "<localleader>lq", "Log", "Compiler log" },
    { "<localleader>le", "Errors", "Errors and warnings" },
    { "<localleader>la", "BuildOnSave toggle", "Toggle build on save" },
    { "<localleader>lV", "View", "Open PDF" },
    { "<localleader>lv", "ForwardSearch", "PDF forward search" },
  }) do
    local action = "<Cmd>TexTools" .. entry[2] .. "<CR>"
    if vim.tbl_contains({ "bib", "bst" }, vim.bo[bufnr].filetype) then
      local methods = {
        Build = "build",
        CancelBuild = "cancel_build",
        CancelAllBuilds = "cancel_all_builds",
        BuildStatus = "show_build_status",
        BuildOutput = "build_output",
        Log = "build_log",
        Errors = "build_errors",
        ["BuildOnSave toggle"] = "build_on_save",
        View = "view",
        ForwardSearch = "forward_search",
      }
      action = function()
        local ok, err = require("tex-tools")[methods[entry[2]]]()
        if not ok and err then
          vim.notify(err, vim.log.levels.WARN, { title = "tex-tools" })
        end
      end
    end
    vim.keymap.set("n", entry[1], action, { buffer = bufnr, desc = entry[3] })
  end
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
end

function M.setup(bufnr)
  local function map(key, action, description, modes)
    vim.keymap.set(modes or "n", key, action, { buffer = bufnr, remap = true, desc = description })
  end
  local function plug(key, action, description, modes)
    map(key, "<Plug>(TexTools" .. action .. ")", description, modes)
  end

  M.setup_actions(bufnr)
  -- The plugin publishes Plug endpoints; this configuration owns physical keys.
  for key, action in pairs({
    ["<localleader>lt"] = "Outline",
    ["<localleader>lc"] = "Clean",
    ["<localleader>lC"] = "CleanFull",
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
    { "<localleader>ls", "Main select", "Select main document" },
    { "<localleader>lB", "Compiler toggle", "Switch compiler" },
  }) do
    map(entry[1], "<Cmd>TexTools" .. entry[2] .. "<CR>", entry[3])
  end
  map("<localleader>lr", function()
    local viewer = require("tex-tools.viewer").detect().method
    vim.cmd("TexToolsInverseSearch " .. viewer)
  end, "Show inverse-search setup")
end

return M
