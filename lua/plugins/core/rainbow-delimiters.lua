return {
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "BufReadPost",
    submodules = false,
    opts = {
      -- Disable the parsing of markdown files.
      -- Problem happens when there are LaTeX codes in a markdown file.
      blacklist = { "markdown", "markdown_inline" },
    },
    main = "rainbow-delimiters.setup",
  },
}
