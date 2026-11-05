local function check()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  assert(vim.fn.exists(":ConfigInfo") == 2)
  assert(vim.fn.exists(":Titlecase") == 2)
  local info = require("config").info()
  assert(info.paths.config == vim.fn.stdpath("config"))
  assert(info.paths.state == vim.fn.stdpath("state"))
  assert(vim.g.mapleader == " " and vim.g.maplocalleader == " ")
  assert(vim.g.loaded_netrw == 1 and vim.g.loaded_netrwPlugin == 1)
  assert(vim.bo.textwidth == 120 and vim.bo.softtabstop == -1)
  assert(vim.o.autoread and vim.o.undofile and vim.o.confirm)
  assert(
    vim.fs.normalize(vim.o.undodir):gsub("/+$", "") == vim.fs.joinpath(vim.fn.stdpath("state"), "undo"),
    "Persistent undo must use Neovim's default state directory"
  )
  assert(#vim.api.nvim_get_autocmds({ group = "ConfigLsp", event = "LspAttach" }) == 1)
  assert(#vim.api.nvim_get_autocmds({ group = "ConfigCore", event = "FileType" }) == 1)
  for name in pairs(package.loaded) do
    assert(not name:match("^config%.legacy[%.]?"), "Startup loaded an archived module: " .. name)
  end
  local plugins = require("lazy.core.config").plugins
  assert(info.plugins.initialized)
  assert(not plugins.showkeys and not package.loaded.showkeys, "Screencast must use keymap-tools")
  assert(vim.fn.exists(":ShowkeysToggle") == 0, "Legacy showkeys command remains")
  local screencast = require("keymap_tools.config").get().showkeys
  assert(not screencast.enabled and screencast.maxkeys == 5, "Screencast must remain opt-in with five keys")
  assert(not require("keymap_tools").showkeys.is_enabled())
  assert(not package.loaded["keymap_tools.showkeys"], "Inactive screencast must stay lazy")
  for _, entry in ipairs(info.plugins.entries) do
    local plugin = assert(plugins[entry.name])
    assert(entry.directory == plugin.dir and entry.loaded == not not plugin._.loaded)
    assert(entry.source == (plugin._.is_local and "local" or "git"))
  end
  assert(not plugins["mini.comment"], "Commenting must use Neovim's native implementation")
  assert(not plugins.undotree, "Snacks undo must not depend on the Undotree plugin")
  assert(not plugins["fidget.nvim"] and not package.loaded.fidget, "Fidget must be removed")
  assert(plugins["notification-tools.nvim"]._.loaded, "Notifications must be available at startup")
  assert(plugins["input-tools.nvim"]._.loaded, "Command-line UI must load at startup")
  assert(require("input-tools").status().notifications, "Native message handoff must be active")
  assert(not plugins["noice.nvim"] and not package.loaded.noice, "Noice must remain disabled")
  assert(not package.loaded["snacks.notifier"], "Snacks must not compete for notification ownership")
  assert(not plugins["smartyank.nvim"], "Yank synchronization must use the native clipboard provider")
  assert(not plugins["nvim-ufo"] and not plugins["promise-async"], "Folding must use the native implementation")
  assert(not plugins["virt-column.nvim"] and not plugins["nvim-scrollbar"])
  assert(plugins["ui-tools.nvim"]._.loaded, "Editor UI helpers must load at startup")
  assert(not plugins["todo-comments.nvim"] and not plugins["nvim-highlight-colors"])
  assert(require("ui_tools.colors").enabled and require("ui_tools.todo").enabled)
  assert(plugins["motion-tools.nvim"]._.loaded, "Motion search feedback must load at startup")
  assert(not plugins["flash.nvim"] and not plugins["nvim-hlslens"] and not plugins["mini.bracketed"])
  assert(require("ui_tools.render").sources.guide, "ui-tools must own the column guide")
  assert(not package.loaded["features.column_guide"] and not package.loaded.scrollbar)
  local languages = require("languages").current()
  local features = require("config.context").current().selection.features
  assert(not plugins.vimtex and not plugins["nvim-texlabconfig"])
  assert(not package.loaded["tex-tools"], "TeX tools must stay lazy before a TeX buffer")
  local function opts(name)
    return require("lazy.core.plugin").values(assert(plugins[name], name), "opts", false)
  end
  -- Opening a file must supply completion capabilities before LSP enable/start;
  -- interactive completion waits for the first input event.
  vim.cmd.edit(vim.env.NVIM_TEST_TMP .. "/sample.py")
  if vim.v.errmsg == "E31: No such mapping" then
    vim.v.errmsg = ""
  end
  assert(not plugins["completion-tools.nvim"]._.loaded, "Opening a file initialized completion UI")
  local cmp = require("completion-tools")
  assert(not cmp.get_status().configured, "Capability lookup initialized the completion engine")
  local completion = cmp.get_lsp_capabilities().textDocument.completion
  local function check_completion(capabilities, name)
    local actual = capabilities.textDocument.completion
    local operations = assert(capabilities.workspace.fileOperations, "Missing file operations: " .. tostring(name))
    for _, key in ipairs({
      "dynamicRegistration",
      "didCreate",
      "willCreate",
      "didRename",
      "willRename",
      "didDelete",
      "willDelete",
    }) do
      assert(operations[key] == true, "Missing file-operation capability: " .. tostring(name) .. "/" .. key)
    end
    assert(vim.deep_equal(vim.tbl_deep_extend("force", actual, completion), actual), name)
  end
  assert(plugins["lsp-tools.nvim"]._.loaded and plugins["nvim-lspconfig"]._.loaded)
  local selected, active = {}, {}
  for _, server in ipairs(require("lsp-tools").server_status()) do
    selected[server.name] = server
  end
  assert(vim.tbl_count(selected) == #languages.servers, "Only profile-selected servers may be managed")
  for _, name in ipairs(languages.servers) do
    local server = assert(selected[name])
    assert(vim.lsp.config[name], name .. " has no native config")
    assert(server.enabled or server.pending, name .. " must be active or waiting for its filetype")
    check_completion(vim.lsp.config[name].capabilities, name)
    if server.enabled then
      assert(server.managed, name .. " must be managed by lsp-tools")
      check_completion(_G.config_test_lsp_enabled[name], name)
      active[#active + 1] = name
    else
      assert(_G.config_test_lsp_enabled[name] == nil, name .. " enabled before its filetype")
    end
  end
  local active_info = require("config").info()
  assert(vim.deep_equal(active_info.languages.servers, languages.servers))
  assert(vim.deep_equal(active_info.lsp.enabled_servers, active))
  vim.api.nvim_exec_autocmds("InsertEnter", {})
  assert(
    plugins["completion-tools.nvim"]._.loaded and cmp.get_status().configured,
    "First InsertEnter must initialize completion"
  )
  local runtime_count = 0
  for _, path in ipairs(vim.opt.rtp:get()) do
    if path == plugins["completion-tools.nvim"].dir then
      runtime_count = runtime_count + 1
    end
  end
  assert(runtime_count == 1, "Completion runtime must not be duplicated after input initialization")
  for _, name in ipairs(active) do
    assert(vim.deep_equal(vim.lsp.config[name].capabilities, _G.config_test_lsp_enabled[name]), name)
  end
  for _, config in ipairs(_G.config_test_lsp_starts) do
    check_completion(config.capabilities, config.name)
  end
  assert(not vim.lsp.is_enabled("kdl"))
  assert(vim.fn.exists(":ConfigToolsInstall") == 2)
  assert(vim.fn.maparg("<Plug>(TexToolsSmartEnter)", "i") == "", "TeX mapping leaked into startup buffer")

  local completion_spec = opts("completion-tools.nvim")
  assert(completion_spec.providers.lazydev == nil)
  assert((completion_spec.providers.copilot ~= nil) == features.ai)
  assert((completion_spec.keymap["<A-i>"] ~= nil) == features.ai)
  assert(not plugins["copilot.lua"] and not package.loaded["copilot.client"])
  assert(vim.fn.exists(":CompletionToolsCopilot") == 2)
  assert(not plugins["blink.cmp"] and not package.loaded["blink.cmp"])
  for _, name in ipairs({ "blink-copilot", "blink-cmp-dictionary", "blink-cmp-spell", "colorful-menu.nvim" }) do
    assert(not plugins[name], "Unadapted Blink extension must not enter the active spec: " .. name)
  end
  assert((plugins["nvim-dap"] ~= nil) == not not features.debugging)
  assert((plugins["task-tools.nvim"] ~= nil) == not not features.tasks)
  assert(not plugins["overseer.nvim"] and not plugins["compile.nvim"])
  assert(not plugins["snacks.nvim"] and not package.loaded.snacks, "Snacks must be removed")
  assert((vim.fn.maparg("<A-i>", "n") ~= "") == not not features.tasks)
  assert((vim.fn.maparg("<A-i>", "t") ~= "") == not not features.tasks)
  assert(
    (plugins["workspace-tools.nvim"] ~= nil) == (not not features.sessions or require("languages").is_enabled("python"))
  )
  assert(not plugins["venv-selector.nvim"])
  assert(not plugins["auto-session"] and not package.loaded["auto-session"])
  for _, name in ipairs({ "barbar.nvim", "lualine.nvim", "copilot-lualine" }) do
    assert(not plugins[name], "Old bar plugin remains configured: " .. name)
  end
  assert(require("ui_tools.bufferline").enabled and require("ui_tools.statusline").enabled)
  for _, key in ipairs({
    "<A-1>",
    "<A-9>",
    "<A-h>",
    "<A-l>",
    "<A-S-,>",
    "<A-S-.>",
    "<A-<>",
    "<A->>",
    "<A-w>",
    "<A-u>",
  }) do
    assert(vim.fn.maparg(key, "n", false, true).callback, "Missing buffer mapping: " .. key)
  end
  assert((plugins["codecompanion.nvim"] ~= nil) == not not features.ai)
  assert((plugins["tex-tools.nvim"] ~= nil) == require("languages").is_enabled("latex"))
  assert(not plugins["lazydev.nvim"] and not plugins["vim-startuptime"] and not plugins["vim-suda"])
  assert((opts("lsp-tools.nvim").lua ~= nil) == require("languages").is_enabled("lua"))
  assert(not plugins["mason.nvim"] and not package.loaded.mason)
  assert(opts("toolchain-tools.nvim").tools.path == "append")
  local tools = {}
  for _, requirement in ipairs(opts("toolchain-tools.nvim").requirements()) do
    tools[requirement.provider .. ":" .. requirement.name] = requirement
  end
  assert(tools["parser:regex"] and tools["tool:codespell"])
  for _, tool in ipairs(languages.tools) do
    if tool.package then
      assert(tools["tool:" .. tool.package], tool.package)
    end
  end
  assert(plugins["toolchain-tools.nvim"]._.loaded, "Managed parser versions must activate before editing")
  assert(not package.loaded["nvim-treesitter"], "Startup must not invoke the legacy installer API")
  vim.cmd("ToolchainPlan")
  assert(plugins["toolchain-tools.nvim"]._.loaded)
  assert(not package.loaded.mason and not package.loaded["mason-registry"])
  assert(#require("toolchain").status() == 0, "Planning must not start installations")
  local parser = require("toolchain.parsers").info("lua")
  assert(parser.session and parser.intact, "Managed Lua parser/query version must be active")
  assert(vim.api.nvim_get_runtime_file("parser/lua.so", false)[1] == parser.session .. "/parser/lua.so")
  for _, requirement in pairs(tools) do
    if requirement.provider == "parser" then
      assert(
        require("toolchain.parsers").info(requirement.name).intact,
        "Managed artifacts are not current: " .. requirement.name
      )
    end
  end
  assert(vim.bo.filetype == "toolchain")
  vim.api.nvim_win_close(0, true)

  -- Exercise actual plugin setup, not just spec merging.
  require("lazy").load({ plugins = { "conform.nvim", "nvim-lint", "completion-tools.nvim" } })
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
  assert(vim.bo.textwidth == 120)
  local tex_enabled = require("languages").is_enabled("latex")
  -- Test the plugin-owned buffer mapping; the old <M-m> shortcut was removed.
  assert((vim.fn.maparg("<Plug>(TexToolsSmartEnter)", "i", false, true).buffer == 1) == tex_enabled)
  if tex_enabled then
    assert(vim.b.tex_tools_generation, "TeX tools did not attach")
    assert(not vim.b.vimtex and not package.loaded["texlabconfig"])
    assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "LaTeX Tree-sitter did not start")
    assert(vim.bo.syntax == "", "Legacy TeX syntax competes with native conceal")
    local tex_options = require("tex-tools.config").options
    assert(tex_options.conceal.enabled and not tex_options.conceal.math_symbols)
    assert(tex_options.lsp == "texquill")
    assert(tex_options.mappings and not tex_options.smart_enter)
    local server = vim.lsp.config.texquill
    assert(server.init_options.build.executable == "latexmk" and server.init_options.build.onSave)
    assert(server.init_options.diagnostics.chktex.enabled)
    assert(vim.deep_equal(server.init_options.diagnostics, server.settings.latex.diagnostics))
    assert(server.cmd[1] == require("languages.latex.lsp").executable())
    assert(server.cmd[2] == "--stdio")
    assert(_G.config_test_lsp_enabled.texquill and not _G.config_test_lsp_enabled.texlab)
    assert(tex_options.build.profiles.latexmk.executable == "latexmk")
    assert(tex_options.build.profiles.xelatex.engine == "xelatex")
  end
  vim.cmd.edit(vim.env.NVIM_TEST_TMP .. "/sample.py")
  assert(vim.bo.filetype == "python")
  -- Neovim's Python undo_ftplugin uses silent! unmap even when no_python_maps is set.
  -- lazy.nvim replays FileType while loading venv-selector, leaving this caught error.
  if vim.v.errmsg == "E31: No such mapping" then
    vim.v.errmsg = ""
  end
  assert(vim.fn.maparg("<Plug>(TexToolsSmartEnter)", "i") == "")
  assert(vim.bo.makeprg == [["$NVIM_PYTHON_MAKE" %:p:S]])
  if require("languages").is_enabled("vue") then
    vim.cmd.edit(vim.env.NVIM_TEST_TMP .. "/sample.vue")
    assert(vim.bo.filetype == "vue")
    assert(vim.list_contains(vim.lsp.config.vtsls.filetypes, "vue"))
    assert(vim.lsp.is_enabled("vue_ls"))
    assert(type(tools["tool:vue-language-server"].post_install_async) == "function")
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

-- Headless startup covers VimEnter. tests/tui.py covers the real VeryLazy path.
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
