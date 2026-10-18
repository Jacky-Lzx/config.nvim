local platform = require("utils.platform")
local displayline = platform.skim_displayline()
local zathura = platform.executable("zathura")

return {
  settings = {
    texlab = {
      build = {
        executable = "latexmk",
        args = { "-pdf", "-synctex=1", "-interaction=nonstopmode", "-file-line-error", "%f" },
        onSave = true,
        forwardSearchAfter = false,
      },
      -- Use Skim for preview and forward search
      -- Native inverse search: :TexToolsInverseSearch skim (one-time viewer setup).
      forwardSearch = displayline and {
        executable = displayline,
        args = { "%l", "%p", "%f" },
      } or (zathura and {
        executable = zathura,
        args = { "--synctex-forward", "%l:1:%f", "%p" },
      } or nil),
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
