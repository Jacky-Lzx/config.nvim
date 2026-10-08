local editor = dofile(vim.fn.stdpath("config") .. "/tests/editor.lua")
local remote, wait, feed = editor.remote, editor.wait, editor.feed
local mode = vim.env.NVIM_TEST_THEME_MODE
editor.run(function()
  local status = remote("return require('config.plugins').status()")
  if mode == "missing" or mode == "disabled" or mode == "core" then
    assert(remote("return vim.g.colors_name == 'habamax' and not package.loaded.catppuccin"))
    assert(not status.features.theme.active)
    if mode == "missing" then
      assert(status.features.theme.enabled and not status.features.theme.available)
      assert(status.features.input.active and status.features.picker.active)
    elseif mode == "disabled" then
      assert(not status.features.theme.enabled)
      assert(status.features.input.active and status.features.picker.active)
    else
      assert(not status.started and not status.enabled)
      assert(remote("return not package.loaded.lazy"))
    end
    return
  end
  assert(status.features.theme.active and status.features.theme.available)
  assert(remote("return vim.g.colors_name == 'catppuccin-mocha' and vim.o.termguicolors"))
  assert(remote("return not package.loaded['blink.cmp'] and not package.loaded.snacks"))
  remote([[
    local function hl(name, link)
      return vim.api.nvim_get_hl(0, { name = name, link = link or false })
    end
    local colors = require("catppuccin.palettes").get_palette("mocha")
    local function color(value) return tonumber(value:sub(2), 16) end
    _G.config_theme_check = function()
      for _, name in ipairs({ "Normal", "NormalNC", "NormalFloat", "FloatBorder" }) do
        assert(hl(name).bg == nil, name .. " must retain transparent background")
      end
      assert(hl("Normal").fg == color(colors.text))
      assert(hl("LineNr").fg == color(colors.surface2))
      assert(hl("Visual").bg == color(colors.overlay0))
      assert(hl("Search", true).link == "SelectionInactive")
      assert(hl("CurSearch").bg == color(colors.mauve))
      assert(hl("CurSearch").fg == 0x4b3566)
      assert(hl("IncSearch", true).link == "CurSearch")
      assert(hl("MatchParen").bold and hl("MatchParen").fg == color(colors.base))
      assert(hl("LspSignatureActiveParameter").bg == color(colors.overlay0))
      assert(hl("DiagnosticVirtualTextError").italic)
      assert(hl("LspInlayHint").bg == nil and hl("LspInlayHint").fg == color(colors.overlay0))
      assert(hl("SnacksPickerListCursorLine").bg == 0x2a2b3d)
      assert(hl("SnacksPickerPreviewCursorLine").bg == 0x2a2b3d)
      assert(hl("SnacksPickerMatch", true).link == "SelectionInactive")
      assert(hl("SnacksPickerSearch", true).link == "SelectionInactive")
    end
    _G.config_theme_check()
    require("config").setup()
    assert(vim.g.colors_name == "catppuccin-mocha")
    _G.config_theme_check()
    vim.cmd.colorscheme("habamax")
    vim.cmd.colorscheme("catppuccin-nvim")
    _G.config_theme_check()
    vim.api.nvim_set_hl(0, "Search", { bg = "#ffffff" })
    vim.cmd.colorscheme("catppuccin-nvim")
    _G.config_theme_check()
    vim.cmd("checkhealth config")
    local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    assert(report:find("theme plugins are available", 1, true), report)
    assert(not report:find("ERROR", 1, true), report)
    vim.cmd.enew()
  ]])
  local integrations = remote("return require('catppuccin').options.integrations")
  if mode == "only" then
    assert(not status.features.input.active and not status.features.picker.active)
    assert(not integrations.blink_cmp.enabled and not integrations.snacks.enabled)
    assert(remote("return not package.loaded['blink.cmp'] and not package.loaded.snacks"))
    feed("ihello<Esc>")
    assert(remote("return vim.api.nvim_get_current_line()") == "hello")
  else
    assert(integrations.blink_cmp.enabled and integrations.snacks.enabled)
    assert(remote("return vim.api.nvim_get_hl(0, { name = 'BlinkCmpMenuBorder', link = false }).bg == nil"))
    feed("ihello<Esc>")
    assert(remote("return package.loaded['blink.cmp'] ~= nil"))
    assert(remote("return vim.api.nvim_get_hl(0, { name = 'BlinkCmpLabel', link = false }).fg == 0x9399b2"))
    remote("vim.bo.modified = false; vim.cmd.file('theme.txt')")
    feed(" sb")
    wait("local p = require('snacks').picker.get()[1]; return p and p.list:count() > 0 and vim.fn.mode() == 'i'")
    remote([[
      local p = require("snacks").picker.get()[1]
      assert(vim.api.nvim_win_is_valid(p.input.win.win))
      assert(vim.api.nvim_get_hl(0, { name = "SnacksPickerInput", link = false }).bg == nil)
      _G.config_theme_check()
    ]])
    feed("<CR>")
    wait("return #require('snacks').picker.get() == 0")
  end
  assert(remote("return vim.fn.filereadable(require('catppuccin').options.compile_path .. '/mocha') == 1"))
end, "Theme checks: " .. mode .. " passed")
