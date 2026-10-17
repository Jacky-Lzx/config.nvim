return {
  {
    "Jacky-Lzx/compile.nvim",
    dev = true,
    main = "compile",
    cmd = { "Compile", "Recompile", "CompileStop", "CompileOpen" },
    keys = {
      { "<leader>mc", "<cmd>Compile<cr>", desc = "[Compile] Enter command" },
      { "<leader>mr", "<cmd>Recompile<cr>", desc = "[Compile] Run again" },
      { "<leader>ms", "<cmd>CompileStop<cr>", desc = "[Compile] Stop" },
      { "<leader>mo", "<cmd>CompileOpen<cr>", desc = "[Compile] Open output" },
    },
    dependencies = {
      {
        "folke/which-key.nvim",
        optional = true,
        opts = {
          spec = {
            { "<leader>m", group = "[Compile]" },
          },
        },
      },
    },
    opts = {},
  },
}
