local M = {}
local function annotate(spec, origin)
  spec.origin = spec.origin or origin
  for _, child in ipairs(spec.children or {}) do
    annotate(child, spec.origin)
  end
  return spec
end
-- Explicit module lists keep startup deterministic and avoid directory scans.
local groups = {
  ui = { "ui.theme-tools", "ui.notification-tools", "ui.input-tools", "ui.ui-tools" },
  navigation = {
    "navigation.keymap-tools",
    "navigation.selection-tools",
    "navigation.file-tools",
    "navigation.motion-tools",
    "navigation.images",
  },
  editing = { "editing.pairs", "editing.editing-tools" },
  coding = {
    "coding.toolchain",
    "coding.snippet-tools",
    "coding.completion",
    "coding.lsp-tools",
    "third_party.conform",
    "third_party.nvim-lint",
  },
  git = { "git.git-tools" },
  integrations = { "integrations.debug-tools", "third_party.wakatime" },
  ai = {},
  debugging = { "disabled.nvim-dap" },
  tasks = { "tasks.task-tools" },
  sessions = { "sessions.workspace-tools" },
}
function M.project(path)
  local file = vim.fs.find(".nvim-plugins.lua", { path = path or vim.uv.cwd(), upward = true, type = "file" })[1]
  if not file then
    return {}
  end
  local contents = vim.secure.read(file)
  if not contents then
    return {}
  end
  local chunk, err = load(contents, "@" .. file)
  assert(chunk, err)
  local specs = chunk()
  assert(type(specs) == "table" and vim.islist(specs), file .. " must return a list of native plugin specs")
  for _, spec in ipairs(specs) do
    annotate(spec, file)
  end
  return specs
end
function M.build(selection)
  local context = selection and require("config.context").initialize(selection) or require("config.context").current()
  local specs, owners = {}, {}
  local function add(entries, origin)
    for _, entry in ipairs(entries) do
      if type(entry) == "string" then
        add(require(entry), entry)
      else
        specs[#specs + 1] = annotate(vim.deepcopy(entry), origin or "config.specs")
        if (entry.source or entry.dir) and entry.enabled ~= false then
          owners[entry.id] = true
        end
      end
    end
  end
  local function group(name)
    for _, module in ipairs(groups[name]) do
      local path = "plugins." .. module
      add(require(path), path)
    end
  end
  for _, name in ipairs({ "ui", "navigation", "editing", "coding", "git", "integrations" }) do
    group(name)
  end
  for _, name in ipairs(require("config.features").names) do
    if context.selection.features[name] then
      group(name)
    end
  end
  add(context.languages.plugins)
  add(M.project())
  local selected = {}
  for _, spec in ipairs(specs) do
    if owners[spec.id] then
      selected[#selected + 1] = spec
    end
  end
  return selected
end
return M
