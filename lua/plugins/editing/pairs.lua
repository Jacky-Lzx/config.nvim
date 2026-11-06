local template_rules = {
  pairs = { ["`"] = { close = "`" } },
  multi_pairs = { ["${"] = {} },
}

local function outside_fence(ctx)
  return not ctx.fence
end

local comment_rules = {
  multi_pairs = { ["/*"] = { close = "*/", newline = true, surround = "c" } },
}

return {
  {
    config = function(ctx)
      require("features.toggles").map({
        id = "pairing",
        scope = "session",
        get = function()
          local pairs = package.loaded.pairs
          if pairs then
            return pairs.status().enabled
          end
        end,
        action = function()
          return require("pairs").toggle()
        end,
      })
      require("config.bindings").set("pairs.nvim", {
        -- Preserve the existing surround prefix and load on the first Normal/Visual action.
        { "s", "<NOP>", mode = { "n", "x", "o" } },
        { "sa", mode = { "n", "x" }, desc = "Add surrounding" },
        { "sr", desc = "Replace surrounding" },
        { "sd", desc = "Delete surrounding" },
        { "sf", mode = { "n", "x", "o" }, desc = "Find surrounding right" },
        { "sF", mode = { "n", "x", "o" }, desc = "Find surrounding left" },
        { "sh", desc = "Highlight surrounding" },
        { "sn", desc = "Update surrounding search range" },
      })
      require("pairs").setup(ctx.opts)
    end,
    main = "pairs",
    id = "pairs.nvim",
    source = "Jacky-Lzx/pairs.nvim",
    version = "main",
    dev = true,
    opts = {
      treesitter = true,
      surround = { enabled = true, treesitter = true },
      rainbow = {
        enabled = true,
        highlights = {
          "RainbowDelimiterRed",
          "RainbowDelimiterYellow",
          "RainbowDelimiterBlue",
          "RainbowDelimiterOrange",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
      },
      pairs = {
        ["("] = { space = true },
        ["["] = { space = true },
        ["{"] = { space = true },
      },
      tex_environments = { abstract = "text", theorem = "text", proof = "text" },
      mappings = { cr = true },
      filetypes = {
        markdown = {
          pairs = {
            ["["] = { space = false },
          },
          multi_pairs = {
            ["```"] = {},
            ["~~~"] = {},
            ["**"] = { surround = "*", condition = outside_fence },
            ["~~"] = { surround = "~", condition = outside_fence },
          },
        },
        c = vim.deepcopy(comment_rules),
        cpp = vim.deepcopy(comment_rules),
        tex = { multi_pairs = { ["$$"] = {}, ["\\("] = { space = true }, ["\\["] = {} } },
        plaintex = { multi_pairs = { ["$$"] = {}, ["\\("] = { space = true }, ["\\["] = {} } },
        javascript = vim.deepcopy(template_rules),
        javascriptreact = vim.deepcopy(template_rules),
        typescript = vim.deepcopy(template_rules),
        typescriptreact = vim.deepcopy(template_rules),
        python = {
          multi_pairs = {
            [string.rep('"', 3)] = { space = true },
            [string.rep("'", 3)] = { space = true },
          },
        },
      },
    },
  },
}
