local function visual_range()
  return { math.min(vim.fn.line("."), vim.fn.line("v")), math.max(vim.fn.line("."), vim.fn.line("v")) }
end
local function on_attach(buf)
  local git = require("git_tools")
  local function map(mode, key, callback, desc)
    vim.keymap.set(mode, key, callback, { buffer = buf, desc = "[Git] " .. desc, silent = true })
  end
  for key, direction in pairs({ ["]h"] = "next", ["[h"] = "prev", ["]H"] = "last", ["[H"] = "first" }) do
    map("n", key, function()
      if vim.wo.diff then
        local motion = (direction == "prev" or direction == "first") and "[c" or "]c"
        if direction == "first" or direction == "last" then
          motion = vim.fn.line("$") .. motion
        end
        vim.cmd.normal({ motion, bang = true })
      else
        git.nav_hunk(direction)
      end
    end, direction .. " hunk")
  end
  map("n", "<leader>ggs", git.stage_hunk, "Stage hunk")
  map("x", "<leader>ggs", function()
    git.stage_hunk({ range = visual_range() })
  end, "Stage selected lines")
  map("n", "<leader>ggu", git.unstage_hunk, "Unstage hunk")
  map("x", "<leader>ggu", function()
    git.unstage_hunk({ range = visual_range() })
  end, "Unstage selected lines")
  map("n", "<leader>ggr", git.reset_hunk, "Reset hunk")
  map("x", "<leader>ggr", function()
    git.reset_hunk({ range = visual_range() })
  end, "Reset selected lines")
  map("n", "<leader>ggS", git.stage_buffer, "Stage buffer")
  map("n", "<leader>ggU", git.unstage_buffer, "Unstage buffer")
  map("n", "<leader>ggR", git.reset_buffer, "Reset buffer")
  map("n", "<leader>ggp", git.preview_hunk, "Preview hunk")
  map("n", "<leader>ggd", git.diffthis, "Diff buffer against index")
  map("n", "<leader>ggD", function()
    git.diffthis("HEAD~1")
  end, "Diff buffer against HEAD~1")
  map("n", "<leader>ggq", git.quickfix, "Buffer hunks to quickfix")
  map("n", "<leader>ggQ", function()
    git.quickfix({ all = true })
  end, "Repository hunks to quickfix")
  map({ "o", "x" }, "ih", git.select_hunk, "Current hunk")
end
return {
  {
    config = function(ctx)
      local function state(name)
        return function(ctx)
          if name == "compare" and not ctx.win then
            return nil
          end
          local git = package.loaded.git_tools
          if git then
            return git.get_state(ctx)[name]
          end
        end
      end
      local toggles = require("features.toggles")
      toggles.map({
        id = "git_compare",
        scope = "tab",
        get = state("compare"),
        action = function()
          return require("git_tools").toggle_compare()
        end,
        notify = false,
      })
      toggles.map({
        id = "git_overlay",
        scope = "buffer",
        get = state("overlay"),
        action = function(ctx)
          return require("git_tools").toggle_overlay(ctx.buf)
        end,
        notify = false,
      })
      for id, option in pairs({ git_blame = "line_blame", git_word_diff = "word_diff", git_signs = "signs" }) do
        toggles.map({
          id = id,
          scope = "session",
          get = state(option),
          action = function()
            return require("git_tools").toggle(option)
          end,
        })
      end
      require("config.bindings").set("git-tools.nvim", {
        {
          "<leader>ggC",
          function()
            require("git_tools").status({ backend = "native" })
          end,
          desc = "[Git] Changed files",
        },
        {
          "<leader>ggv",
          function()
            require("git_tools").branches({ all = true })
          end,
          desc = "[Git] Branches",
        },
        {
          "<leader>ggt",
          function()
            require("git_tools").stash({ backend = "native" })
          end,
          desc = "[Git] Stash",
        },
        {
          "<leader>ggo",
          function()
            require("git_tools").browse({ what = "repo" })
          end,
          desc = "[Git] Repository page",
        },
        {
          "<leader>ggO",
          function()
            require("git_tools").browse({ what = "branch" })
          end,
          desc = "[Git] Branch page",
        },
        {
          "<C-g>",
          function()
            require("git_tools").lazygit()
          end,
          desc = "[Git] Lazygit",
        },
        {
          "<leader>ggc",
          function()
            require("git_tools").changes({ backend = "native" })
          end,
          desc = "[Git] Change hunks",
        },
        {
          "<leader>ggl",
          function()
            require("git_tools").log({ backend = "native" })
          end,
          desc = "[Git] Log",
        },
        {
          "<leader>ggf",
          function()
            require("git_tools").file_history({ backend = "native" })
          end,
          desc = "[Git] File history",
        },
        {
          "<leader>ggh",
          function()
            require("git_tools").line_history()
          end,
          desc = "[Git] Line history",
        },
        {
          "<leader>ggb",
          function()
            require("git_tools").blame()
          end,
          desc = "[Git] Blame line",
        },
        {
          "<leader>ggB",
          function()
            require("git_tools").browse()
          end,
          desc = "[Git] Browse file",
        },
        {
          "<leader>ggB",
          function()
            require("git_tools").browse({ range = visual_range() })
          end,
          mode = "x",
          desc = "[Git] Browse selected lines",
        },
        {
          "<leader>ggy",
          function()
            require("git_tools").browse({ copy = true })
          end,
          desc = "[Git] Copy permanent URL",
        },
        {
          "<leader>ggy",
          function()
            require("git_tools").browse({ copy = true, range = visual_range() })
          end,
          mode = "x",
          desc = "[Git] Copy selected line URL",
        },
        {
          "<leader>ggm",
          function()
            require("git_tools").merge()
          end,
          desc = "[Git] Merge conflicts",
        },
      })
      require("git_tools").setup(ctx.opts)
    end,
    id = "git-tools.nvim",
    source = "Jacky-Lzx/git-tools.nvim",
    version = "main",
    dev = true,
    main = "git_tools",
    opts = { buffer = { signs = false, numhl = true, on_attach = on_attach } },
  },
}
