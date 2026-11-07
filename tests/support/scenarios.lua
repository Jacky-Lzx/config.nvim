-- Fixed capability fixtures are separate from lua/config/selection.lua.
return {
  full = {
    profiles = { "base", "web", "native", "data", "writing", "optional" },
    features = { ai = true, debugging = true, tasks = true, sessions = true },
  },
  tasks = { profiles = { "data" }, features = { tasks = true } },
  python_environment = { profiles = { "data" }, features = { debugging = true, tasks = true, sessions = false } },
  lua = { profiles = { "base" }, features = {} },
  minimal = { profiles = {}, features = {} },
  python = { profiles = { "data" }, features = { ai = false, debugging = true, tasks = false, sessions = false } },
  writing = { profiles = { "writing" }, features = { tasks = true } },
}
