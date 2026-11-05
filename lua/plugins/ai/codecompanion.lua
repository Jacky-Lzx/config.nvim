return {
  {
    bootstrap = require("config.bindings").bootstrap("codecompanion.nvim", {
      {
        "<leader>cca",
        "<CMD>CodeCompanionActions<CR>",
        mode = { "n", "v" },
        noremap = true,
        silent = true,
        desc = "CodeCompanion actions",
      },
      {
        "<leader>cci",
        "<CMD>CodeCompanion<CR>",
        mode = { "n", "v" },
        noremap = true,
        silent = true,
        desc = "CodeCompanion inline",
      },
      {
        "<leader>ccc",
        "<CMD>CodeCompanionChat Toggle<CR>",
        mode = { "n", "v" },
        noremap = true,
        silent = true,
        desc = "CodeCompanion chat (toggle)",
      },
      {
        "<leader>ccp",
        "<CMD>CodeCompanionChat Add<CR>",
        mode = { "v" },
        noremap = true,
        silent = true,
        desc = "CodeCompanion chat add code",
      },

      -- Assume you have a prompt defined in your markdown prompts directory with the alias "essay"
      {
        "<leader>cce",
        "<CMD>CodeCompanion /essay<CR>",
        mode = { "v" },
        noremap = true,
        silent = true,
        desc = "CodeCompanion /essay",
      },
    }, nil),
    main = "codecompanion",
    id = "codecompanion.nvim",
    source = "olimorris/codecompanion.nvim",
    dependencies = {
      "plenary.nvim",
      "toolchain-tools.nvim",
    },
    opts = {
      send_code = false,

      -- Ignore the warnings for the upcoming v18.0.0
      ignore_warnings = true,

      display = {
        chat = {
          fold_reasoning = false,
          show_reasoning = true,
          show_settings = false, -- If show settings, can not change adapter during the chat
        },
      },

      adapters = {
        http = {
          lm_studio = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              formatted_name = "LM Studio",
              env = {
                api_key = "LM_STUDIO_API_KEY_CODECOMPANION",
                url = "http://localhost:1234",
              },
              handlers = {
                parse_message_meta = function(_, data)
                  local extra = data.extra
                  if extra and extra.reasoning_content then
                    data.output.reasoning = { content = extra.reasoning_content }
                    if data.output.content == "" then
                      data.output.content = nil
                    end
                  end
                  return data
                end,
              },
            })
          end,
          deepseek = function()
            return require("codecompanion.adapters").extend("deepseek", {
              env = {
                api_key = function()
                  return os.getenv("DEEPSEEK_API_KEY_NEOVIM")
                end,
              },
              schema = {
                max_tokens = {
                  default = 16384,
                },
              },
              parameters = {
                max_tokens = 16384,
              },
            })
          end,
        },
      },
      -- opts = {
      --   language = "English", -- "English"|"Chinese"
      -- },

      strategies = {
        chat = {
          adapter = "lm_studio",
          keymaps = {
            stop = false,
          },
        },
        inline = { adapter = "lm_studio" },
      },

      prompt_library = {
        markdown = {
          -- Path to your markdown prompts directory
          dirs = {
            require("utils.paths").config("configs", "codecompanion_prompts"),
          },
        },
      },
    },

    config = function(ctx)
      local opts = ctx.opts
      require("integrations.codecompanion_notifications").setup()

      local codecompanion = require("codecompanion")
      codecompanion.setup(opts)
    end,
  },

  -- Configure render-markdown to recognize the codecompanion filetype
  {
    id = "render-markdown.nvim",
    opts = { file_types = { "markdown", "codecompanion" } },
  },
  {
    id = "img-clip.nvim",
    opts = {
      filetypes = {
        codecompanion = {
          prompt_for_file_name = false,
          template = "[Image]($FILE_PATH)",
          use_absolute_path = true,
        },
      },
    },
  },
}
