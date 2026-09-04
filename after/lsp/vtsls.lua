-- Merged over the bundled lspconfig `lsp/vtsls.lua` (after/ has lower priority).
-- Adds the @vue/typescript-plugin so vtsls also handles <script> blocks in .vue files,
-- and adds the `vue` filetype (missing from the default config).
local vue_ls_path = require("utils.vue_lsp").server_path()

local config = {
  filetypes = require("utils.vue_lsp").filetypes,
}

if vue_ls_path then
  config.settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = vue_ls_path,
            languages = { "vue" },
            configNamespace = "typescript",
          },
        },
      },
    },
  }
end

return config
