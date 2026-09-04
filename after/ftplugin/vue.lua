vim.treesitter.start()

-- Vue LSP (vtsls + vue_ls) 的启动逻辑已迁移：
-- - 配置:   after/lsp/vtsls.lua, after/lsp/ts_ls.lua
-- - 路径解析 / TS7 修复 / vim.lsp.enable: lua/utils/vue_lsp.lua
--   （由 lua/plugins/languages/vue.lua 中的 lspconfig config 在加载时调用）
