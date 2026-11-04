local function action(name, ...)
  local args = { ... }
  return function()
    return require("motion_tools")[name](unpack(args))
  end
end

local keys = {
  { "<leader>f", action("jump"), mode = { "n", "x", "o" }, desc = "[Motion] Jump" },
  { "<leader>F", action("treesitter"), mode = "n", desc = "[Motion] Select syntax node" },
  {
    "<leader>F",
    action("treesitter", { search = true }),
    mode = { "x", "o" },
    desc = "[Motion] Search syntax node",
  },
  { "<leader>j", action("lines"), mode = { "n", "x", "o" }, desc = "[Motion] Jump to line" },
  { "<leader>k", action("lines"), mode = { "n", "x", "o" }, desc = "[Motion] Jump to line" },
  { "<C-f>", action("cmdline_jump"), mode = "c", expr = true, desc = "[Motion] Search labels" },
}
for _, key in ipairs({ "n", "N", "*", "#", "g*", "g#" }) do
  keys[#keys + 1] = { key, action("search", key), desc = "[Motion] Search " .. key }
end
for target, suffix in pairs({ diagnostic = "d", quickfix = "q", location = "l", jump = "j", treesitter = "t" }) do
  local modes = (target == "diagnostic" or target == "treesitter") and { "n", "x", "o" } or "n"
  for lhs, direction in pairs({
    ["[" .. suffix] = "prev",
    ["]" .. suffix] = "next",
    ["[" .. suffix:upper()] = "first",
    ["]" .. suffix:upper()] = "last",
  }) do
    keys[#keys + 1] =
      { lhs, action("navigate", target, direction), mode = modes, desc = "[Motion] " .. direction .. " " .. target }
  end
end
-- [b / ]b belong to ui-tools and follow the visible bufferline order.
for lhs, direction in pairs({ ["[B"] = "first", ["]B"] = "last" }) do
  keys[#keys + 1] = { lhs, action("navigate", "buffer", direction), desc = "[Motion] " .. direction .. " buffer" }
end
for _, spec in ipairs({ { "i", "more" }, { "o", "less" } }) do
  for prefix, direction in pairs({ ["["] = "prev", ["]"] = "next" }) do
    keys[#keys + 1] = {
      prefix .. spec[1],
      action("navigate", "indent", direction, { change = spec[2] }),
      mode = { "n", "x", "o" },
      desc = "[Motion] " .. direction .. " " .. spec[2] .. " indent",
    }
  end
end

return {
  {
    dir = require("utils.platform").dev_plugin_root() .. "/motion-tools.nvim",
    name = "motion-tools.nvim",
    main = "motion_tools",
    lazy = false, -- Native / and ? feedback must work before the first mapped motion.
    opts = { mappings = false }, -- This spec owns keys; preserve other plugin owners.
    keys = keys,
  },
}
