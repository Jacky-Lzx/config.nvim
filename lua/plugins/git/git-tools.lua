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
  map("n", "<leader>ggP", git.toggle_overlay, "Toggle inline preview")
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
    dir = require("utils.platform").dev_plugin_root() .. "/git-tools.nvim",
    name = "git-tools.nvim",
    main = "git_tools",
    event = { "BufReadPost", "BufNewFile" },
    cmd = "GitTools",
    opts = { buffer = { signs = false, numhl = true, on_attach = on_attach } },
    keys = {
      {
        "<leader>ggc",
        function()
          require("git_tools").status({ backend = "delta" })
        end,
        desc = "[Git] Changes",
      },
      {
        "<leader>ggl",
        function()
          require("git_tools").log({ backend = "delta" })
        end,
        desc = "[Git] Log",
      },
      {
        "<leader>ggf",
        function()
          require("git_tools").file_history({ backend = "delta" })
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
      {
        "<leader>Dt",
        function()
          require("git_tools").toggle_compare()
        end,
        desc = "[Git] Toggle diff view",
      },
      {
        "<leader>to",
        function()
          require("git_tools").toggle_overlay()
        end,
        desc = "[Git] Toggle diff overlay",
      },
      {
        "<leader>tgb",
        function()
          require("git_tools").toggle("line_blame")
        end,
        desc = "[Git] Toggle line blame",
      },
      {
        "<leader>tgw",
        function()
          require("git_tools").toggle("word_diff")
        end,
        desc = "[Git] Toggle word diff",
      },
      {
        "<leader>tgs",
        function()
          require("git_tools").toggle("signs")
        end,
        desc = "[Git] Toggle signs",
      },
    },
  },
}
