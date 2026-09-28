local function check()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  local plugins = require("lazy.core.config").plugins
  local languages = require("languages").current()
  local features = require("config.selection").features
  local function opts(name)
    return require("lazy.core.plugin").values(assert(plugins[name], name), "opts", false)
  end
  require("lazy").load({ plugins = { "nvim-lspconfig" } })
  for _, name in ipairs(languages.servers) do
    assert(vim.lsp.is_enabled(name), name .. " is not enabled")
    assert(vim.lsp.config[name], name .. " has no native config")
  end
  assert(not vim.lsp.is_enabled("kdl"))
  assert(vim.fn.exists(":ConfigToolsInstall") == 2)
  assert(vim.fn.maparg("<M-m>", "i") == "", "TeX mapping leaked into startup buffer")

  local blink = opts("blink.cmp")
  assert((blink.sources.providers.lazydev ~= nil) == require("languages").is_enabled("lua"))
  assert((blink.sources.providers.copilot ~= nil) == not not features.ai)
  assert((blink.keymap["<A-i>"] ~= nil) == not not features.ai)
  assert((plugins["nvim-dap"] ~= nil) == not not features.debugging)
  assert((plugins["overseer.nvim"] ~= nil) == not not features.tasks)
  assert((plugins["auto-session"] ~= nil) == not not features.sessions)
  assert((plugins["copilot-lualine"] ~= nil) == not not features.ai)
  assert((plugins["codecompanion.nvim"] ~= nil) == not not features.ai)
  assert((plugins["vimtex"] ~= nil) == require("languages").is_enabled("latex"))
  assert((plugins["lazydev.nvim"] ~= nil) == require("languages").is_enabled("lua"))
  local tools = opts("mason.nvim")
  for _, tool in ipairs(languages.tools) do
    if tool.mason then
      assert(vim.list_contains(tools.ensure_installed, tool.mason), tool.mason)
    end
  end

  -- Exercise actual plugin setup, not just spec merging.
  require("lazy").load({ plugins = { "conform.nvim", "nvim-lint", "blink.cmp" } })
  assert(vim.deep_equal(require("conform").formatters_by_ft, opts("conform.nvim").formatters_by_ft))
  assert(vim.deep_equal(require("lint").linters_by_ft, opts("nvim-lint").linters_by_ft))
  if features.debugging then
    require("lazy").load({ plugins = { "nvim-dap" } })
    if require("languages").is_enabled("python") then
      assert(require("dap").configurations.python[1].type == "python")
    end
  end

  -- Filetype hooks still run when language plugins are disabled.
  vim.cmd.edit(vim.env.NVIM_TEST_TMP .. "/sample.tex")
  assert(vim.bo.filetype == "tex")
  assert(vim.bo.textwidth == 0)
  assert(not vim.bo.formatoptions:find("t", 1, true))
  local tex_enabled = require("languages").is_enabled("latex")
  assert((vim.fn.maparg("<M-m>", "i", false, true).buffer == 1) == tex_enabled)
  if tex_enabled then
    assert(vim.g.vimtex_syntax_enabled == true)
    assert(vim.b.vimtex, "VimTeX did not initialize")
    assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "LaTeX Tree-sitter did not start")
    assert(vim.bo.syntax ~= "", "VimTeX syntax required for conceal is disabled")
    assert(vim.g.vimtex_syntax_conceal.math_delimiters == 1)
  end
  vim.cmd.edit(vim.env.NVIM_TEST_TMP .. "/sample.py")
  assert(vim.bo.filetype == "python")
  -- Neovim's Python undo_ftplugin uses silent! unmap even when no_python_maps is set.
  -- lazy.nvim replays FileType while loading venv-selector, leaving this caught error.
  if vim.v.errmsg == "E31: No such mapping" then
    vim.v.errmsg = ""
  end
  assert(vim.fn.maparg("<M-m>", "i") == "")
  assert(vim.bo.makeprg:find("python", 1, true))
  if require("languages").is_enabled("vue") then
    vim.cmd.edit(vim.env.NVIM_TEST_TMP .. "/sample.vue")
    assert(vim.bo.filetype == "vue")
    assert(vim.list_contains(vim.lsp.config.vtsls.filetypes, "vue"))
    assert(vim.lsp.is_enabled("vue_ls"))
    assert(type(tools.post_install["vue-language-server"]) == "function")
  end

  -- Reapplying the theme must preserve user highlights.
  local visual = vim.api.nvim_get_hl(0, { name = "Visual", link = false })
  vim.cmd.colorscheme("catppuccin-nvim")
  assert(vim.deep_equal(visual, vim.api.nvim_get_hl(0, { name = "Visual", link = false })))
  vim.wait(150, function()
    return false
  end, 10)
  assert(vim.v.errmsg == "", vim.v.errmsg)
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end

-- Let VimEnter/VeryLazy finish before exercising the configured plugins.
vim.defer_fn(function()
  local ok, err = xpcall(check, debug.traceback)
  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  else
    io.stdout:write("Startup and filetype checks passed (" .. (vim.env.NVIM_TEST_SCENARIO or "default") .. ")\n")
    vim.cmd("quitall!")
  end
end, 100)
