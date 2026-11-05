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
  ui = { "theme-tools", "notification-tools", "input-tools", "nvim-web-devicons", "ui-tools" },
  navigation = { "keymap-tools", "selection-tools", "file-tools", "motion-tools", "images" },
  editing = { "pairs", "editing-tools" },
  coding = { "toolchain", "snippet-tools", "completion", "nvim-lspconfig", "lsp-tools", "conform", "nvim-lint" },
  git = { "git-tools" },
  integrations = { "debug-tools", "wakatime" },
  ai = { "copilot", "codecompanion" },
  debugging = { "nvim-dap" },
  tasks = { "task-tools" },
  sessions = { "workspace-tools" },
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
      local path = "plugins." .. name .. "." .. module
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
  if owners["codecompanion.nvim"] then
    add({ { id = "plenary.nvim", source = "nvim-lua/plenary.nvim", start = false } })
  end
  add(M.project())
  local selected, obsidian_options = {}, {}
  for _, spec in ipairs(specs) do
    if owners[spec.id] then
      if spec.id == "obsidian.nvim" then
        obsidian_options = vim.tbl_deep_extend("force", obsidian_options, spec.opts or {})
      end
      selected[#selected + 1] = spec
    end
  end
  if type(obsidian_options.workspaces) ~= "table" or #obsidian_options.workspaces == 0 then
    selected = vim.tbl_filter(function(spec)
      return spec.id ~= "obsidian.nvim"
    end, selected)
  else
    selected[#selected + 1] =
      { id = "image-tools.nvim", origin = "config.specs:obsidian", opts = { insert = { directory = "assets/imgs" } } }
  end
  return selected
end
return M
