return {
  {
    "toppair/peek.nvim",
    enabled = require("utils.platform").executable("deno") ~= nil,
    cmd = { "MarkdownPreview" },
    build = "deno task --quiet build:fast",
    opts = {},
    config = function(_, opts)
      require("peek").setup(opts)
      vim.api.nvim_create_user_command("MarkdownPreview", require("peek").open, {})
    end,
  },
}
