return {
  {
    "obsidian-nvim/obsidian.nvim",
    -- Workspaces are supplied by the vault's .lazy.lua after shared opts are merged.
    cond = function(plugin)
      local opts = require("lazy.core.plugin").values(plugin, "opts", false)
      return type(opts.workspaces) == "table" and #opts.workspaces > 0
    end,
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
        match_case = false,
        -- Trigger completion at 2 chars.
        min_chars = 2,
        -- Set to false to disable new note creation in the picker
        create_new = false,
      },

      picker = {
        -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', 'mini.pick' or 'snacks.picker'.
        name = "snacks.picker",
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
