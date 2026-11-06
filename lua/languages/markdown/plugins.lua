return {
  {
    id = "markdown-tools.nvim",
    -- Local package until the new plugin is published.
    dir = require("utils.platform").dev_plugin_root() .. "/markdown-tools.nvim",
    main = "markdown_tools",
    mount = "on-demand",
    ft = { "markdown" },
    config = function(ctx)
      require("languages.markdown.tools").setup(ctx.opts)
    end,
    opts = {
      link_handler = function(link, ctx)
        local obsidian = package.loaded.obsidian_tools
        if obsidian then
          return obsidian.follow_link(link, ctx)
        end
      end,
      preview = function()
        require("peek").open()
      end,
      export = function(ctx)
        if not require("config.context").current().selection.features.tasks then
          return false, "Enable the tasks feature to export Markdown"
        end
        if ctx.file == "" or vim.bo[ctx.buf].modified then
          return false, "Save the Markdown file before exporting"
        end
        local spec = require("features.tasks").definitions(ctx)[1]
        if not spec then
          return false, "No Markdown PDF task is configured"
        end
        return require("task_tools").run(spec)
      end,
    },
  },
  "plugins.third_party.peek",
  "plugins.third_party.render-markdown",
  {
    id = "obsidian-tools.nvim",
    dir = require("utils.platform").dev_plugin_root() .. "/obsidian-tools.nvim",
    main = "obsidian_tools",
    enabled = true,
    optional = true,
    mount = "on-demand",
    ft = { "markdown" },
    dependencies = { "markdown-tools.nvim" },
    config = function(ctx)
      require("integrations.obsidian").setup(ctx.opts)
    end,
    children = {
      {
        id = "image-tools.nvim",
        source = "Jacky-Lzx/image-tools.nvim",
        opts = { insert = { directory = "assets/imgs" } },
      },
    },
    opts = {
      notes_subdir = "notes",
      daily_notes = { folder = "dailies", default_tags = { "daily-notes" } },
      templates = { folder = "templates", date_format = "%Y-%m-%d", time_format = "%H:%M" },
      note_id = function(title)
        local suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        return tostring(os.time()) .. (suffix ~= "" and "-" .. suffix or "")
      end,
    },
  },
}
