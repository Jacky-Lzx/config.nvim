vim.api.nvim_set_hl(0, "BlinkCmpItemKindMinuet", { fg = "#CBA6F7" })
return {
  {
    "milanglacier/minuet-ai.nvim",
    opts = {
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
    },
  },
  { "nvim-lua/plenary.nvim" },

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
            timeout_ms = 3000,
            score_offset = 200, -- Gives minuet higher priority among suggestions
            opts = {
              kind_icon = "",
              kind_hl = "DevIconCopilot",
            },
          },
        },
      },
      -- Recommended to avoid unnecessary request
      completion = { trigger = { prefetch_on_insert = false } },
    },
  },
}
