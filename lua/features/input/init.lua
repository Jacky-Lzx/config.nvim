local M = {}

function M.requirements()
  return {
    { "blink.cmp", "lua/blink/cmp/init.lua" },
    { "LuaSnip", "lua/luasnip/init.lua" },
  }
end

function M.specs()
  local pairing = require("features.input.pairing")
  local dependencies = { "LuaSnip" }
  local specs = {
    {
      "L3MON4D3/LuaSnip",
      lazy = true,
      version = "v2.5.0",
      build = "make install_jsregexp",
      cmd = { "LuaSnipList", "LuaSnipEdit" },
      config = function()
        require("features.input.snippets").setup()
      end,
    },
  }
  if pairing.source().available then
    dependencies[#dependencies + 1] = "pairs.nvim"
    specs[#specs + 1] = {
      name = "pairs.nvim",
      lazy = true,
      dir = pairing.source().dir,
      cmd = { "PairsToggle", "PairsInspect" },
      config = function()
        pairing.setup()
      end,
      keys = {
        {
          "<leader>tp",
          function()
            require("pairs").toggle()
          end,
          desc = "Toggle pairing",
        },
      },
    }
  end
  specs[#specs + 1] = {
    "saghen/blink.cmp",
    version = "v1.10.2",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = dependencies,
    opts = require("features.input.completion").options(),
  }
  return specs
end

return M
