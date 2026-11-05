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
  require("keymap_tools").register("editing-tools.nvim", metadata)
end

return {
  {
    dir = require("utils.platform").dev_plugin_root() .. "/editing-tools.nvim",
    name = "editing-tools.nvim",
    main = "editing_tools",
    cmd = "EditingTools",
    opts = {},
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = describe,
      })
    end,
    keys = function()
      local keys = {}
      -- Keep Vim's URI opener reachable after gx becomes exchange.
      local uri = vim.fn.maparg("gx", "n", false, true)
      if vim.fn.maparg("gX", "n") == "" and (uri.desc or ""):find("URI under cursor", 1, true) then
        keys[#keys + 1] = { "gX", uri.callback or uri.rhs, desc = uri.desc }
      end
      for _, prefix in ipairs({ "a", "i", "an", "in", "al", "il" }) do
        keys[#keys + 1] = { prefix, mode = { "o", "x" } }
      end
      keys[#keys + 1] = { "g[", desc = "[Editing] Go to object start" }
      keys[#keys + 1] = { "g]", desc = "[Editing] Go to object end" }
      for prefix, action in pairs({
        ["g="] = "Evaluate arithmetic",
        gx = "Exchange",
        gm = "Duplicate",
        cr = "Replace from register",
        gs = "Sort",
        ga = "Align with preview",
      }) do
        keys[#keys + 1] = { prefix, mode = { "n", "x" }, desc = "[Editing] " .. action }
        keys[#keys + 1] = { prefix .. prefix:sub(-1), mode = "n", desc = "[Editing] " .. action .. " lines" }
      end
      return keys
    end,
  },
}
