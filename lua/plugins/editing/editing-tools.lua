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
    config = function(ctx)
      do
        if vim.fn.maparg("gX", "n") == "" then
          vim.keymap.set("n", "gX", function()
            vim.ui.open(vim.fn.expand("<cfile>"))
          end, { desc = "Open URI under cursor" })
        end
        vim.api.nvim_create_autocmd("VimEnter", {
          once = true,
          callback = describe,
        })
      end
      require("config.bindings").set("editing-tools.nvim", function()
        local keys = {}
        -- Keep Vim's URI opener reachable after gx becomes exchange.
        local uri = vim.fn.maparg("gx", "n", false, true)
        if vim.fn.maparg("gX", "n") == "" and (uri.desc or ""):find("URI under cursor", 1, true) then
          keys[#keys + 1] = { "gX", uri.callback or uri.rhs, desc = uri.desc }
        end
        local function plug(lhs, action, mode)
          keys[#keys + 1] = {
            lhs,
            "<Plug>(EditingTools-" .. action .. ")",
            mode = mode,
            desc = "[Editing] " .. action,
          }
        end
        for lhs, action in pairs({
          i = "inside",
          a = "around",
          ["in"] = "inside_next",
          an = "around_next",
          il = "inside_prev",
          al = "around_prev",
        }) do
          plug(lhs, action, { "o", "x" })
        end
        plug("g[", "goto_start", "n")
        plug("g]", "goto_end", "n")
        plug("mI", "insert_visual", "x")
        plug("mA", "append_visual", "x")
        for lhs, action in pairs({
          ["g="] = "evaluate",
          gx = "exchange",
          gm = "multiply",
          cr = "replace",
          gs = "sort",
          ga = "align",
        }) do
          plug(lhs, action, { "n", "x" })
          plug(lhs .. lhs:sub(-1), action .. "-line", "n")
        end
        return keys
      end)
      require("editing_tools").setup(ctx.opts)
    end,
    id = "editing-tools.nvim",
    source = "Jacky-Lzx/editing-tools.nvim",
    version = "main",
    dev = true,
    main = "editing_tools",
    opts = {},
  },
}
