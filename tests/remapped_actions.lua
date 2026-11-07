-- Exercise the same workflows after changing declarations, without editing user keys.
local bindings = require("config.bindings")
local set = bindings.set
local remaps = {
  ["tasks.prompt"] = "<leader>xp",
  ["tasks.rerun"] = "<leader>xr",
  ["tasks.build_output"] = "<leader>xo",
  ["tasks.build_quickfix"] = "<leader>xq",
  ["tasks.terminal"] = "<leader>xt",
  ["tasks.list"] = "<leader>xl",
  ["tasks.select"] = "<leader>xs",
  ["tasks.run_file"] = "<leader>xa",
  ["toggle.wrap"] = "<leader>xw",
  ["keymaps.pick"] = "<leader>x?",
  ["files.tree"] = "<leader>xf",
  ["files.reveal"] = "<leader>xe",
  ["files.cwd"] = "<leader>xd",
  ["selection.files"] = "<leader>xsF",
}
-- Native toggle registration consumes its declaration before bindings.set().
local toggles = require("features.toggles")
local map = toggles.map
toggles.map = function(owner, lhs, opts)
  return map(owner, remaps["toggle." .. owner.id] or lhs, opts)
end
bindings.set = function(owner, entries)
  entries = vim.deepcopy(type(entries) == "function" and entries() or entries)
  for _, entry in ipairs(entries) do
    entry[1] = remaps[entry.id] or entry[1]
  end
  return set(owner, entries)
end
