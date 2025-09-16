return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.diff",
      "j-hui/fidget.nvim",
      -- Configure render-markdown to recognize the codecompanion filetype
      {
        "MeanderingProgrammer/render-markdown.nvim",
        optional = true,
        ft = { "codecompanion" },
      },
    },

    -- stylua: ignore
    keys = {
      {"<leader>cca", "<CMD>CodeCompanionActions<CR>",     mode = {"n", "v"}, noremap = true, silent = true, desc = "CodeCompanion actions"      },
      {"<leader>cci", "<CMD>CodeCompanion<CR>",            mode = {"n", "v"}, noremap = true, silent = true, desc = "CodeCompanion inline"       },
      {"<leader>ccc", "<CMD>CodeCompanionChat Toggle<CR>", mode = {"n", "v"}, noremap = true, silent = true, desc = "CodeCompanion chat (toggle)"},
      {"<leader>ccp", "<CMD>CodeCompanionChat Add<CR>",    mode = {"v"}     , noremap = true, silent = true, desc = "CodeCompanion chat add code"},
    },

    opts = {
      send_code = false,

      display = {
        chat = {
          show_settings = false, -- If show settings, can not change adapter during the chat
        },
        diff = {
          layout = "vertical", -- "vertical"|"horizontal" split for default provider
          opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
          provider = "mini_diff", -- "default"|"mini_diff"
        },
      },

      adapters = {
        http = {
          deepseek = function()
            return require("codecompanion.adapters").extend("deepseek", {
              env = {
                api_key = function()
                  return os.getenv("DEEPSEEK_API_KEY_NEOVIM")
                end,
              },
            })
          end,
        },
      },
      -- opts = {
      --   language = "English", -- "English"|"Chinese"
      -- },

      strategies = {
        chat = { adapter = "copilot" },
        inline = { adapter = "copilot" },
      },

      prompt_library = {
        ["Essay - Stochastic Computing"] = {
          strategy = "chat",
          description = "Help spot mistakes and improve the quality of your essay",
          -- This opts table must exist, because the source code does not handle the case when opts is nil -- 2025.09.05
          opts = {
            auto_submit = true,
          },
          prompts = {
            {
              role = "system",
              content = [[
Assume the role of a meticulous proofreader with a strong background in Stochastic Computing. 
Your task is to scrutinize an academic manuscript, focusing specifically on correcting grammatical errors and refining syntax to meet the highest standards of academic writing. 
Pay close attention to subject-verb agreement, tense consistency, and the proper use of academic tone and vocabulary. 
Examine complex sentences to ensure clarity and coherence, breaking down overly complicated structures if necessary. 
Your goal is to produce a polished, error-free document that communicates ideas clearly, concisely, and effectively, without detracting from the scholarly content and contributions of the work. 
Organize your changes in two lists, one list for grammatical errors and another list for syntax improvements. 
The content should be precise and concise, avoiding any unnecessary embellishments or alterations to the original meaning. 
The item in the list should have the following format:
- "The data was collected quick."
  - Issue: Adverb "quick" is used incorrectly instead of the adverbial form "quickly" to modify the verb "collected".
  - Change: `quick` -> `quickly`
              ]],
            },
            -- {
            --   role = "user",
            --   content = function(context)
            --     local text = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            --
            --     return "I have the following code:\n\n```" .. context.filetype .. "\n" .. text .. "\n```\n\n"
            --   end,
            --   opts = {
            --     contains_code = true,
            --   },
            -- },
          },
        },
      },
    },
    init = function()
      require("utils.codecompanion_fidget_spinner"):init()
    end,
  },

  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = {
      "fang2hou/blink-copilot",
      {
        "zbirenbaum/copilot.lua",
        event = "VeryLazy",
        opts = {
          suggestion = {
            enabled = false,
          },
          panel = {
            enabled = false,
          },
          filetypes = {
            markdown = true,
            help = true,
          },
        },
      },
    },
    opts = {
      sources = {
        default = { "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
            opts = {
              kind_icon = "",
              kind_hl = "DevIconCopilot",
            },
          },
        },
      },
    },
  },

  -- Customization of the Copilot icon
  {
    "nvim-tree/nvim-web-devicons",
    opts = {
      override = {
        copilot = {
          icon = "",
          color = "#cba6f7", -- Catppuccin.mocha.mauve
          name = "Copilot",
        },
      },
    },
  },
}
