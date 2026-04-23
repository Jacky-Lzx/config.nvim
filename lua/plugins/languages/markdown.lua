-- Set the markdown style with the tabindent values set in the config instead of the built-in value
vim.g.markdown_recommended_style = 0

-- FIXME: Vale is not configured correctly. It doesn't work
-- vim.lsp.enable("vale_ls")

-- To enable project-wide features of marksman (cross-file references and completions), either
--  - Have a git repository
--  - Have a `.markdman.toml` file in the project root

-- marksman does not support configure its settings through lsp.
-- You can only configure it in `.marksman.toml`
-- For available configurations, see `https://github.com/artempyanykh/marksman/blob/main/Tests/default.marksman.toml`
vim.lsp.enable("marksman")

vim.lsp.config("harper_ls", {
  filetypes = { "markdown", "text", "tex", "plaintex" },
  settings = {
    ["harper-ls"] = {
      linters = {
        SentenceCapitalization = false,
        SpellCheck = false,
        Spaces = false,
        NoFrenchSpaces = false,
      },
    },
  },
})
vim.lsp.enable("harper_ls")

local M = {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts_extend = { "ensure_installed", "indent.disable" },
    opts = {
      ensure_installed = { "markdown", "markdown_inline" },
      indent = { disable = { "markdown" } }, -- Indentation at bullet points is worse
    },
  },

  {
    "mason-org/mason.nvim",
    optional = true,
    opts_extend = { "ensure_installed" },
    opts = { ensure_installed = { "marksman", "harper-ls", "prettierd", "prettier", "mmdc" } },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        -- Conform will run the first available formatter
        markdown = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },

  {
    "toppair/peek.nvim",
    conds = require("conds").is_mac,
    cmd = { "MarkdownPreview" },
    build = "deno task --quiet build:fast",
    opts = {},
    config = function(_, opts)
      require("peek").setup(opts)
      vim.api.nvim_create_user_command("MarkdownPreview", require("peek").open, {})
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    keys = {
      { "<leader>tm", desc = "Enable render markdown" },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons", -- if you prefer nvim-web-devicons
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      -- Disable by default, use keymap to toggle
      enabled = false,
      -- The plugin also provides a completion method using blink.cmp
      -- However, just enabling the general LSP conmpletions is enough
      completions = {
        lsp = { enabled = true },
      },
      -- Vim modes that will show a rendered view of the markdown file, :h mode(), for all enabled
      -- components. Individual components can be enabled for other modes. Remaining modes will be
      -- unaffected by this plugin.
      -- Default: render_modes = { "n", "c", "t" },
      -- Set to true to enable render in all modes
      render_modes = true,
      checkbox = {
        checked = { scope_highlight = "@markup.strikethrough" },
      },
      indent = {
        enabled = true,
        skip_heading = true,
      },
      latex = { enabled = false },

      code = {
        -- Disable the sign shown on the left of the line numbers
        sign = false,
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)

      require("snacks")
        .toggle({
          name = "Render Markdown",
          get = function()
            return require("render-markdown.state").enabled
          end,
          set = function(enabled)
            local m = require("render-markdown")
            if enabled then
              m.enable()
            else
              m.disable()
            end
          end,
        })
        :map("<leader>tm")
    end,
  },

  -- The markview plugin needs to be loaded before nvim-treesitter
  -- {
  --   "nvim-treesitter/nvim-treesitter",
  --   dependencies = {
  --     "OXY2DEV/markview.nvim",
  --   },
  -- },
  --
  -- {
  --   "OXY2DEV/markview.nvim",
  --   -- Do not lazy load this plugin as it is already lazy-loaded.
  --   -- Lazy-loading will cause more time for the previews to load when starting Neovim.
  --   lazy = false,
  --
  --   opts = {
  --     preview = {
  --       modes = { "n", "no", "c", "i" },
  --       filetypes = { "md", "rmd", "quarto", "codecompanion" },
  --       icon_provider = "devicons", -- "internal", "mini" or "devicons"
  --     },
  --   },
  --
  --   -- For blink.cmp's completion
  --   -- source
  --   -- dependencies = {
  --   --     "saghen/blink.cmp"
  --   -- },
  -- },

  {
    "Jacky-Lzx/image-insert.nvim",
    dev = true,
    keys = {
      {
        "<leader>pI",
        function()
          require("image-insert").insert_image({ insert_strategy = "insert_line_after" })
        end,
        desc = "[image-insert] Insert next line",
      },
      {
        "<leader>pi",
        function()
          require("image-insert").insert_image({ insert_strategy = "insert_after" })
        end,
        desc = "[image-insert] Insert after cursor",
      },
      {
        "<leader>PI",
        function()
          require("image-insert").insert_image({ insert_strategy = "insert_line_before" })
        end,
        desc = "[image-insert] Insert prev line",
      },
      {
        "<leader>Pi",
        function()
          require("image-insert").insert_image({ insert_strategy = "insert_before" })
        end,
        desc = "[image-insert] Insert before cursor",
      },
      {
        "<leader>pC",
        function()
          require("image-insert").insert_image({
            process = {
              { cmd = "", extension = "png" },
              { cmd = "", extension = "jpeg" },
              { cmd = "", extension = "avif" },
              { cmd = "convert - avif:-", extension = "avif" },
              { cmd = "magick - -quality 85 png:-", extension = "png" },
              { cmd = "magick - -quality 75 webp:-", extension = "webp" },
            },
          })
        end,
        desc = "[image-insert] Paste image from system clipboard",
      },
      {
        "<leader>pc",
        function()
          Snacks.picker.files({
            ft = { "jpg", "jpeg", "png", "webp", "heic", "avif" },
            -- Override what happens when you press <CR> (confirm)
            actions = {
              confirm = function(picker, _)
                -- Get multi-selection (or current item if nothing is selected)
                local items = picker:selected({ fallback = true })
                -- Convert items -> file paths
                local files = vim.tbl_map(function(it)
                  -- for the files picker items typically have it.file (and it.text)
                  return it.file or it.text
                end, items)

                picker:close()

                -- Schedule if you’re going to open/edit files, etc.
                vim.schedule(function()
                  Snacks.notify("Selected:\n" .. table.concat(files, "\n"), { title = "image-insert.nvim" })

                  for _, file in ipairs(files) do
                    require("image-insert").insert_image({ insert_strategy = "insert_line_after" }, file)
                  end
                end)
              end,
            },
          })
        end,
        desc = "[image-insert] Choose an image to paste",
      },
    },
    opts = {
      dir_path = "Figures",
      prompt_for_file_name = false,
      relative_to_current_file = false,
      process = { cmd = "convert - avif:-", extension = "avif" },
    },
  },

  {
    "HakonHarnes/img-clip.nvim",
    enabled = false,
    dev = true,
    keys = {
      {
        "<leader>pi",
        function()
          require("img-clip").paste_image({ insert_at_current_line = true, insert_at_current_line_after = true })
        end,
        desc = "[Img-Clip] Paste image from system clipboard",
      },
      {
        "<leader>pI",
        function()
          require("img-clip").paste_image({ insert_at_current_line = true, insert_at_current_line_after = false })
        end,
        desc = "[Img-Clip] Paste image from system clipboard",
      },
      {
        "<leader>pc",
        function()
          Snacks.picker.files({
            ft = { "jpg", "jpeg", "png", "webp", "heic", "avif" },
            confirm = function(self, item, _)
              self:close()
              require("img-clip").paste_image({}, "./" .. item.file) -- ./ is necessary for img-clip to recognize it as path
            end,
          })
        end,
        desc = "[Img-Clip] Choose an image to paste",
      },
    },
    opts = {
      default = {
        dir_path = "Figures", ---@type string | fun(): string

        extension = "avif", ---@type string
        -- Convert clipboard image to avif format before saving
        process_cmd = "convert - avif:-", ---@type string
        copy_images = true,
        formats = { "jpeg", "jpg", "png", "heic", "pdf", "avif" }, ---@type string[]

        use_absolute_path = false, ---@type boolean
        relative_to_current_file = false, ---@type boolean

        insert_mode_after_paste = true,

        insert_template_after_cursor = true,
        insert_at_current_line = true,
        insert_at_current_line_after = false,

        show_dir_path_in_prompt = true, ---@type boolean

        prompt_for_file_name = false, ---@type boolean
        file_name = "%y-%m-%d_%H-%M-%S", ---@type string

        -- This setting also affect copying texts using Cmd+v. If it is enabled, when copying texts, a warning about
        -- "the content is not image" will be shown.
        drag_and_drop = { enabled = false },
      },
      filetypes = {
        markdown = {
          -- Encode spaces and special characters in file path
          url_encode_path = true, ---@type boolean

          template = "![$CURSOR]($FILE_PATH)", ---@type string | fun(context: table): string
        },
      },
    },
  },

  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- Recommended, use latest release instead of latest commit
    dependencies = {
      -- Modified img-clip configs for obsidian vaults
      {
        "HakonHarnes/img-clip.nvim",
        optional = true,
        opts = {
          default = {
            dir_path = "assets/imgs", ---@type string | fun(): string
          },
        },
      },
      {
        "Jacky-Lzx/image-insert.nvim",
        optional = true,
        opts = {
          dir_path = "assets/imgs",
        },
      },
      {
        "folke/which-key.nvim",
        optional = true,
        opts = {
          spec = {
            { "<leader>O", group = "[Obsidian]" },
          },
        },
      },
    },
    cmd = { "Obsidian" },
    keys = {
      { "<leader>OO", "<CMD>Obsidian<CR>", desc = "[Obsidian] Picker" },
      { "<leader>OD", "<CMD>Obsidian dailies<CR>", desc = "[Obsidian] Dailies" },
      { "<leader>Og", "<CMD>Obsidian search<CR>", desc = "[Obsidian] Search" },
      { "<leader>Of", "<CMD>Obsidian quick_switch<CR>", desc = "[Obsidian] Quick switch files" },
      { "<leader>Od", "<CMD>Obsidian follow_link<CR>", desc = "[Obsidian] Follow link" },
      { "<leader>Ob", "<CMD>Obsidian backlinks<CR>", desc = "[Obsidian] Back links" },
      { "<leader>Oq", "<CMD>Obsidian quick_switch<CR>", desc = "[Obsidian] Quick switch" },
      -- typos: ignore
      { "<leader>Ot", "<CMD>Obsidian tags<CR>", desc = "[Obsidian] Tags" }, -- codespell:ignore "Ot"
      { "<leader>Op", "<CMD>Obsidian paste_img<CR>", desc = "[Obsidian] Paste image" },
    },

    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      workspaces = {
        {
          name = "Research Workspace",
          path = "~/Research/Obsidian_Workspace",
        },
      },

      -- Keep notes in a specific subdirectory of the vault.
      notes_subdir = "notes",
      -- Where to put new notes. Valid options are
      -- _ "current_dir" - put new notes in same directory as the current buffer.
      -- _ "notes_subdir" - put new notes in the default notes subdirectory.
      new_notes_location = "notes_subdir",

      -- Customize how wiki links are formatted.
      link = {
        style = "wiki",
        format = "absolute",
      },

      legacy_commands = false,

      footer = { enabled = false },

      daily_notes = {
        -- Optional, if you keep daily notes in a separate directory.
        folder = "dailies",
        -- Optional, if you want to change the date format for the ID of daily notes.
        date_format = "%Y-%m-%d",
        -- Optional, if you want to change the date format of the default alias of daily notes.
        alias_format = "%B %-d, %Y",
        -- Optional, default tags to add to each new daily note created.
        default_tags = { "daily-notes" },
        -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
        template = nil,
        -- Optional, if you want `Obsidian yesterday` to return the last work day or `Obsidian tomorrow` to return the next work day.
        workdays_only = false,
      },

      checkbox = {
        enabled = true,
        create_new = false,
        -- order = { " ", "~", "!", ">", "x" },
        order = { " ", "x" },
      },

      completion = {
        -- Enables completion using nvim_cmp
        nvim_cmp = false,
        -- Enables completion using blink.cmp
        blink = true,
        -- Trigger completion at 2 chars.
        min_chars = 2,
        -- Set to false to disable new note creation in the picker
        create_new = false,
      },

      picker = {
        -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', 'mini.pick' or 'snacks.pick'.
        name = "snacks.pick",
        -- Optional, configure key mappings for the picker. These are the defaults.
        -- Not all pickers support all mappings.
        note_mappings = {
          -- Create a new note from your query.
          new = "<C-x>",
          -- Insert a link to the selected note.
          insert_link = "<C-l>",
        },
        tag_mappings = {
          -- Add tag(s) to current note.
          tag_note = "<C-l>",
          -- Insert a tag at the current location.
          insert_tag = "",
        },
      },

      -- Optional, for templates (see https://github.com/obsidian-nvim/obsidian.nvim/wiki/Using-templates)
      templates = {
        folder = "templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
        -- A map for custom variables, the key should be the variable and the value a function.
        -- Functions are called with obsidian.TemplateContext objects as their sole parameter.
        -- See: https://github.com/obsidian-nvim/obsidian.nvim/wiki/Template#substitutions
        substitutions = {},

        -- A map for configuring unique directories and paths for specific templates.
        -- See: https://github.com/obsidian-nvim/obsidian.nvim/wiki/Template#customizations
        customizations = {},
      },

      ---@param id string
      ---@param dir obsidian.Path
      ---@return string
      note_id_func = function(id, dir)
        -- A fix of generating daily notes IDs after version 3.15.0
        -- Refer to `https://github.com/obsidian-nvim/obsidian.nvim/issues/584#issuecomment-3693179057`
        local daily_notes_dir = Obsidian.dir / Obsidian.opts.daily_notes.folder
        if daily_notes_dir == dir then
          return id
        end
        -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
        -- In this case a note with the title 'My new note' will be given an ID that looks
        -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'.
        -- You may have as many periods in the note ID as you'd like—the ".md" will be added automatically
        local suffix = ""
        if id ~= nil then
          -- If title is given, transform it into valid file name.
          suffix = id:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          -- If title is nil, just add 4 random uppercase letters to the suffix.
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
        end
        return tostring(os.time()) .. "-" .. suffix
      end,
    },
  },
}

return M
