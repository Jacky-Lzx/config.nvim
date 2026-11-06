local function describe()
  local objects = {
    { " ", "Whitespace" },
    { '"', "Double-quoted string" },
    { "'", "Single-quoted string" },
    { "`", "Backtick string" },
    { "(", "Parentheses" },
    { ")", "Parentheses" },
    { "[", "Square brackets" },
    { "]", "Square brackets" },
    { "{", "Braces" },
    { "}", "Braces" },
    { "<", "Angle brackets" },
    { ">", "Angle brackets" },
    { "a", "Argument" },
    { "b", "Balanced brackets" },
    { "c", "Class" },
    { "d", "Digits" },
    { "e", "Subword" },
    { "f", "Function" },
    { "g", "Entire buffer" },
    { "i", "Indentation" },
    { "o", "Block, conditional or loop" },
    { "q", "Quoted string" },
    { "t", "Tag" },
    { "u", "Call with member chain" },
    { "U", "Call without member chain" },
    { "_", "Underscore segment" },
    { "w", "Word" },
    { "W", "WORD" },
    { "s", "Sentence" },
    { "p", "Paragraph" },
  }
  local metadata = { modes = { "o", "x" }, groups = {}, hints = {} }
  for prefix, label in pairs({
    i = "Inside",
    a = "Around",
    ["in"] = "Inside next",
    an = "Around next",
    il = "Inside previous",
    al = "Around previous",
  }) do
    metadata.groups[#metadata.groups + 1] = { prefix = prefix, label = label }
    for _, object in ipairs(objects) do
      local native = object[1] == "w" or object[1] == "W" or object[1] == "s" or object[1] == "p"
      if not native or prefix == "i" or prefix == "a" then
        metadata.hints[#metadata.hints + 1] = { keys = prefix .. object[1], desc = object[2] }
      end
    end
  end
  -- Publish cold hints without initializing the editing implementation.
  require("keymap_tools").register("motion-tools.nvim", metadata)
end

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
for lhs, endpoint in pairs({
  i = "inside",
  a = "around",
  ["in"] = "inside_next",
  an = "around_next",
  il = "inside_prev",
  al = "around_prev",
}) do
  keys[#keys + 1] =
    { lhs, "<Plug>(MotionTools-" .. endpoint .. ")", mode = { "o", "x" }, desc = "[Motion] " .. endpoint }
end
for lhs, endpoint in pairs({ ["g["] = "goto_start", ["g]"] = "goto_end" }) do
  keys[#keys + 1] = { lhs, "<Plug>(MotionTools-" .. endpoint .. ")", desc = "[Motion] " .. endpoint }
end
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
    config = function(ctx)
      require("config.bindings").set("motion-tools.nvim", keys)
      require("motion_tools").setup(ctx.opts)
      vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = describe })
    end,
    id = "motion-tools.nvim",
    source = "Jacky-Lzx/motion-tools.nvim",
    version = "main",
    dev = true,
    main = "motion_tools",
    opts = { mappings = false }, -- This spec owns keys; preserve other plugin owners.
  },
}
