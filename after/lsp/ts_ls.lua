-- Only takes effect if you enable `ts_ls` instead of `vtsls`.
-- Registers the @vue/typescript-plugin with typescript-language-server.
local vue_ls_path = require("languages.vue.compatibility").server_path()

local config = {
  filetypes = require("languages.vue.compatibility").filetypes,
}

if vue_ls_path then
  config.init_options = {
    plugins = {
      {
        name = "@vue/typescript-plugin",
        location = vue_ls_path,
        languages = { "vue" },
        configNamespace = "typescript",
      },
    },
  }
end

return config
