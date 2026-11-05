-- -u NONE --noplugin tests invoke init.lua manually. Explicitly perform the
-- native runtime phase there; production startup and PTY tests use Neovim's own.
if not _G.config_test_native_plugins then
  _G.config_test_native_plugins = true
  vim.cmd("runtime! plugin/**/*.{vim,lua}")
end
