return {
  {
    "Jacky-Lzx/compile.nvim",
    init = function()
      require("keymap_tools").register("compile", {
        groups = { { prefix = "<leader>m", label = "[Compile]" } },
      })
    end,
    dev = true,
    main = "compile",
    cmd = { "Compile", "Recompile", "CompileStop", "CompileOpen" },
    keys = {
      { "<leader>mc", "<cmd>Compile<cr>", desc = "[Compile] Enter command" },
      { "<leader>mr", "<cmd>Recompile<cr>", desc = "[Compile] Run again" },
      { "<leader>ms", "<cmd>CompileStop<cr>", desc = "[Compile] Stop" },
      { "<leader>mo", "<cmd>CompileOpen<cr>", desc = "[Compile] Open output" },
    },
    opts = {},
  },
}
