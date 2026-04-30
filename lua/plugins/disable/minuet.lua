vim.api.nvim_set_hl(0, "BlinkCmpItemKindMinuet", { fg = "#a6e3a1" })

return {
  {
    "milanglacier/minuet-ai.nvim",
    enabled = false,
    dependencies = {
      {
        "saghen/blink.cmp",
        optional = true,
        opts = {
          -- keymap = {
          --   -- Manually invoke minuet completion.
          --   ["<A-y>"] = require("minuet").make_blink_map(),
          -- },
          sources = {
            default = { "minuet" },
            providers = {
              minuet = {
                name = "minuet",
                module = "minuet.blink",
                async = true,
                -- Should match minuet.config.request_timeout * 1000,
                -- since minuet.config.request_timeout is in seconds
                timeout_ms = 10000,
                score_offset = 200, -- Gives minuet higher priority among suggestions
                transform_items = function(_, items)
                  for _, item in ipairs(items) do
                    item.kind_icon = ""
                    item.kind_name = "Local LM"
                  end
                  return items
                end,
              },
            },
          },
          -- Recommended to avoid unnecessary request
          completion = { trigger = { prefetch_on_insert = false } },
        },
      },
    },
    opts = {
      -- If completion item has multiple lines, create another completion item
      -- only containing its first line. This option only has impact for cmp and
      -- blink. For virtualtext, no single line entry will be added.
      add_single_line_entry = false,
      provider = "openai_compatible", -- Use an OpenAI-compatible provider
      provider_options = {
        openai_compatible = {
          api_key = "LM_STUDIO_API_KEY", -- The API key can be a placeholder string like 'lm-studio'
          end_point = "http://localhost:1234/v1/chat/completions", -- The default LM Studio server address and port
          name = "LM Studio", -- A custom name for your model
        },
        openai_fim_compatible = {
          api_key = "LM_STUDIO_API_KEY", -- The API key can be a placeholder string like 'lm-studio'
          end_point = "http://localhost:1234/v1/completions", -- The default LM Studio server address and port
          name = "LM Studio", -- A custom name for your model
        },
      },
      request_timeout = 10,
    },
  },
  { "nvim-lua/plenary.nvim" },
}
