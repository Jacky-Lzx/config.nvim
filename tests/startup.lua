local function check()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  assert(vim.fn.exists(":ConfigInfo") == 2)
  assert(vim.fn.exists(":Titlecase") == 2)
  local info = require("config").info()
  assert(info.paths.config == vim.fn.stdpath("config"))
  assert(info.paths.state == vim.fn.stdpath("state"))
  assert(vim.g.mapleader == " " and vim.g.maplocalleader == " ")
  assert(vim.g.loaded_netrw == 1 and vim.g.loaded_netrwPlugin == 1)
  assert(vim.bo.textwidth == 0 and vim.bo.softtabstop == -1)
  assert(vim.o.autoread and vim.o.undofile and vim.o.confirm)
  assert(#vim.api.nvim_get_autocmds({ group = "ConfigLsp", event = "LspAttach" }) == 1)
  assert(#vim.api.nvim_get_autocmds({ group = "ConfigCore", event = "FileType" }) == 1)
  for name in pairs(package.loaded) do
    assert(not name:match("^config%.legacy[%.]?"), "Startup loaded an archived module: " .. name)
  end
  local plugins = require("lazy.core.config").plugins
  local languages = require("languages").current()
  local features = require("config.context").current().selection.features
  local function opts(name)
    return require("lazy.core.plugin").values(assert(plugins[name], name), "opts", false)
  end
  -- Opening a file must configure completion before LSP enable/start, without
  -- manually loading either plugin or entering Insert mode first.
  vim.cmd.edit(vim.env.NVIM_TEST_TMP .. "/sample.py")
  if vim.v.errmsg == "E31: No such mapping" then
    vim.v.errmsg = ""
  end
  assert(plugins["blink.cmp"]._.loaded, "Completion loaded after LSP enable")
  local completion = require("blink.cmp").get_lsp_capabilities().textDocument.completion
  local function check_completion(capabilities, name)
    local actual = capabilities.textDocument.completion
    assert(vim.deep_equal(vim.tbl_deep_extend("force", actual, completion), actual), name)
  end
  for _, name in ipairs(languages.servers) do
    assert(vim.lsp.is_enabled(name), name .. " is not enabled")
    assert(vim.lsp.config[name], name .. " has no native config")
    check_completion(_G.config_test_lsp_enabled[name], name)
  end
  vim.api.nvim_exec_autocmds("InsertEnter", {})
  for _, name in ipairs(languages.servers) do
    assert(vim.deep_equal(vim.lsp.config[name].capabilities, _G.config_test_lsp_enabled[name]), name)
  end
  for _, config in ipairs(_G.config_test_lsp_starts) do
    check_completion(config.capabilities, config.name)
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
  -- The same physical format key must use Conform in attached and unattached buffers.
  local conform = require("conform")
  local original_format, original_lsp_format = conform.format, vim.lsp.buf.format
  local formatted
  conform.format = function(options)
    assert(options.lsp_format == "fallback")
    formatted = vim.api.nvim_get_current_buf()
  end
  vim.lsp.buf.format = function()
    error("The shared format key bypassed Conform")
  end
  local unattached = vim.api.nvim_create_buf(true, false)
  local attached = vim.api.nvim_get_current_buf()
  vim.api.nvim_exec_autocmds("LspAttach", { group = "ConfigLsp", buffer = attached, data = { client_id = 1 } })
  for _, buffer in ipairs({ attached, unattached }) do
    vim.api.nvim_set_current_buf(buffer)
    local mapping = vim.fn.maparg("<leader>gf", "n", false, true)
    assert(mapping.buffer == 0, "LSP attach installed a competing format key")
    local keys = vim.api.nvim_replace_termcodes(vim.g.mapleader .. "gf", true, true, true)
    vim.api.nvim_feedkeys(keys, "xt", false)
    assert(formatted == buffer, "The format key did not operate on the current buffer")
  end
  vim.api.nvim_set_current_buf(attached)
  conform.format, vim.lsp.buf.format = original_format, original_lsp_format
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
  assert(vim.bo.makeprg == [["$NVIM_PYTHON_MAKE" %:p:S]])
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
