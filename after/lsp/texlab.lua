return {
  settings = {
    texlab = {
      -- build = {
      --   executable = "latexmk",
      --   args = {
      --     "%f",
      --   },
      --   onSave = false,
      --   forwardSearchAfter = false,
      -- },
      build = {
        executable = "tectonic",
        args = {
          "-X",
          "compile",
          "%f",
          "--synctex",
          "--keep-logs",
          "--keep-intermediates",
        },
        onSave = false,
        forwardSearchAfter = false,
      },
      -- Use Skim for preview and forward search
      -- The inverse search is configured in "f2fora/nvim-texlabconfig"
      forwardSearch = {
        executable = "/Applications/Skim.app/Contents/SharedSupport/displayline",
        args = { "%l", "%p", "%f" },
      },
      chktex = {
        onOpenAndSave = false,
        onEdit = false,
        additionalArgs = {
          "-wall",
          "-q",
          "-n1",
          "-n3",
          "-n8",
          "-n9",
          "-n22",
          "-n30",
          "-n24",
          "-n17",
          "-e16",
        },
      },
      bibtexFormatter = "texlab", -- @type "texlab" | "latexindent" | "none"; @default "texlab"
      latexFormatter = "none", -- @type "texlab" | "latexindent" | "none"; @default "latexindent"
      -- latexindent = {
      -- ["local"] = "~/.config/latexindent/lzx_settings.yaml", -- local is a reserved keyword
      -- ["local"] = vim.env.HOME .. "/.config/latexindent/lzx_settings.yaml", -- local is a reserved keyword
      -- modifyLineBreaks = true, -- @default false
      -- },
    },
  },
}
