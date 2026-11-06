-- Invoked by tests/tui.py after native startup and ConfigReady.
local temp = assert(vim.uv.fs_realpath(assert(vim.env.NVIM_TEST_TMP)))
local plugins = require("config.plugins").nodes()
local function registered(...)
  for _, name in ipairs({ ... }) do
    assert(plugins[name] and require("config.plugins").initialized(name), "Missing registration for " .. name)
  end
end
local function loaded(name)
  assert(plugins[name] and require("config.plugins").initialized(name), "Did not load " .. name)
end
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
end
local function contents(lines)
  vim.cmd("enew!")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

local function check()
  assert(vim.g.config_ready, "This check must run after the real ConfigReady event")
  registered(
    "dap-tools.nvim",
    "file-tools.nvim",
    "task-tools.nvim",
    "format-tools.nvim",
    "pairs.nvim",
    "editing-tools.nvim"
  )
  for _, name in ipairs({ "nvim-tree.lua", "nvim-lsp-file-operations", "yazi.nvim" }) do
    assert(not plugins[name], "Replaced file plugin still configured: " .. name)
  end
  for _, name in ipairs({ "mini.ai", "mini.align", "mini.operators" }) do
    assert(not plugins[name] and not package.loaded[name], "Replaced editing owner remains: " .. name)
  end
  assert(not plugins.LuaSnip and not package.loaded.luasnip)
  assert(vim.fn.exists(":LuaSnipEdit") == 0 and vim.fn.exists(":SnippetEngine") == 0)
  loaded("ui-tools.nvim")
  assert(not plugins["todo-comments.nvim"] and not plugins["nvim-highlight-colors"])
  assert(not package.loaded["todo-comments"] and not package.loaded["nvim-highlight-colors"])
  assert(require("ui_tools.colors").enabled and require("ui_tools.todo").enabled)
  loaded("motion-tools.nvim")
  assert(not plugins["flash.nvim"] and not plugins["nvim-hlslens"] and not plugins["mini.bracketed"])
  assert(not plugins["copilot.lua"] and not package.loaded["copilot.client"])
  assert(not plugins["mini.surround"] and not plugins["rainbow-delimiters.nvim"])
  assert(not vim.b.tex_tools_generation, "TeX behavior attached to a non-TeX buffer")
  assert(not plugins.vimtex and not plugins["nvim-texlabconfig"])
  for _, command in ipairs({
    "FileTools",
    "FileToolsRead",
    "FileToolsWrite",
    "SudaRead",
    "SudaWrite",
    "StartupTime",
    "EditingTools",
    "TaskToggle",
  }) do
    assert(vim.fn.exists(":" .. command) == 2, "Missing cold command: " .. command)
  end

  local case = vim.env.NVIM_STARTUP_CASE
  -- Some installed plugins use silent! cleanup for absent legacy autocmds and
  -- dictionary watchers. These leave v:errmsg without reporting an error.
  vim.v.errmsg = ""
  if case == "boundaries" or case == "boundaries_files" then
    -- First-save opt-out must preserve whitespace.
    feed(" tfa")
    assert(vim.g.enable_autoformat == false)
    registered("format-tools.nvim")
    vim.cmd.edit(temp .. "/lazy-save.txt")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "keep spaces   " })
    vim.cmd.write()
    loaded("format-tools.nvim")
    assert(vim.api.nvim_get_current_line() == "keep spaces   ", "First save ignored the formatting opt-out")
    feed(" tfa")
    vim.cmd.write()
    assert(vim.api.nvim_get_current_line() == "keep spaces", "Second toggle did not restore formatting")

    vim.fn.mkdir(temp .. "/lazy-cargo", "p")
    vim.cmd.edit(temp .. "/lazy-cargo/Cargo.toml")
    loaded("crates.nvim")
    loaded("pairs.nvim") -- Reading/creating a file enables rainbow before InsertEnter.
    assert(require("pairs.rainbow").status().enabled)
    registered("dap-tools.nvim", "snippet-tools.nvim")
    loaded("file-tools.nvim")
    assert(not package.loaded["file_tools.tree"], "LSP capabilities must not initialize the tree")
    for _, extension in ipairs({ "cpp", "swift" }) do
      vim.cmd.edit(temp .. "/lazy-file." .. extension)
      registered("dap-tools.nvim")
      assert(not package.loaded.dap and not package.loaded["dap_tools.ui"], "Opening source files initialized DAP")
      assert(not package.loaded["file_tools.tree"])
    end
    vim.api.nvim_exec_autocmds("LspAttach", { buffer = 0, data = { client_id = 999999 } })
    registered("dap-tools.nvim")
    assert(not package.loaded["file_tools.tree"])

    if case == "boundaries_files" then
      vim.cmd("FileTools create " .. temp .. "/file-tools-created.txt")
      assert(vim.uv.fs_stat(temp .. "/file-tools-created.txt"))
      assert(not package.loaded["file_tools.tree"], "Core commands must not initialize the tree")
    end
    vim.cmd("FileTools open " .. temp)
    loaded("file-tools.nvim")
    local renamed
    local get_clients = vim.lsp.get_clients
    vim.lsp.get_clients = function(opts)
      if opts and opts.bufnr then
        return {}
      end
      return {
        {
          id = 999,
          config = { root_dir = temp },
          server_capabilities = {
            workspace = {
              fileOperations = {
                didRename = { filters = { { scheme = "file", pattern = { glob = "**" } } } },
              },
            },
          },
          notify = function(_, method, params)
            assert(method == "workspace/didRenameFiles")
            renamed = params.files[1]
          end,
        },
      }
    end
    local from, to = temp .. "/" .. case .. "-old.txt", temp .. "/" .. case .. "-new.txt"
    vim.fn.writefile({ "original" }, from)
    local event, err = require("file_tools").rename(from, to)
    vim.lsp.get_clients = get_clients
    assert(event, err)
    assert(not vim.uv.fs_stat(from) and vim.uv.fs_stat(to))
    assert(renamed and renamed.oldUri == vim.uri_from_fname(from), "First tree use missed rename notifications")
    vim.cmd("FileTools close")
    vim.cmd("TaskToggle")
    loaded("task-tools.nvim")
    vim.cmd("TaskClose")
    feed(" b")
    loaded("dap-tools.nvim")
    assert(require("dap_tools").status().initialized)
    assert(not package.loaded["dap-view"] and not plugins["nvim-dap-view"])
    require("dap_tools").open("breakpoints", true)
    local panel = require("dap_tools.ui").snapshot()
    assert(panel.open and vim.bo[panel.buf].filetype == "daptools")
    require("ui_tools.winbar").refresh()
    assert(vim.wo[panel.win].winbar:find("4:breakpoints", 1, true), "Generic winbar replaced the DAP panel tabs")
    assert(#panel.lines >= 4, "Configured breakpoint was absent from the independent panel")
    feed("q")
    assert(not require("dap_tools.ui").is_open(), "Panel q mapping did not close the configured panel")
  elseif case == "editing" then
    contents({ "a=1", "long=2" })
    vim.fn.writefile({ "Running first alignment" }, vim.env.NVIM_STARTUP_RESULT)
    feed("Vjga")
    loaded("editing-tools.nvim")
    assert(require("editing_tools.align").is_active(), "First alignment did not open preview")
    assert(vim.api.nvim_get_current_line() == "a=1", "Preview changed the source")
    feed("<CR>")
    assert(not require("editing_tools.align").is_active())
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(lines[1]:find("=", 1, true) == lines[2]:find("=", 1, true), vim.inspect(lines))
    contents({ "word" })
    vim.fn.writefile({ "Running first multiply" }, vim.env.NVIM_STARTUP_RESULT)
    feed("gmm")
    loaded("editing-tools.nvim")
    assert(vim.api.nvim_buf_line_count(0) == 2, "First multiply key did not duplicate the line")
    contents({ "(word)" })
    vim.fn.writefile({ "Running first textobject" }, vim.env.NVIM_STARTUP_RESULT)
    feed("di(")
    loaded("editing-tools.nvim")
    assert(vim.api.nvim_get_current_line() == "()", "First textobject key did not operate")
    contents({ "(word)" })
    vim.fn.writefile({ "Running first surround" }, vim.env.NVIM_STARTUP_RESULT)
    feed("sd)")
    loaded("pairs.nvim")
    assert(require("pairs").status().surround.enabled)
    assert(#require("pairs").status().surround.conflicts == 0)
    assert(vim.api.nvim_get_current_line() == "word", "First surround key did not operate")
    contents({ "match match" })
    vim.fn.writefile({ "Running first search" }, vim.env.NVIM_STARTUP_RESULT)
    feed("/match<CR>")
    loaded("motion-tools.nvim")
    assert(not plugins["nvim-scrollbar"] and not package.loaded.scrollbar)
    assert(require("ui_tools.scrollbar").options.search, "ui-tools search markers must stay enabled")
    require("ui_tools.scrollbar").refresh()
  elseif case == "completion" then
    feed(":<Esc>")
    loaded("completion-tools.nvim")
    assert(not plugins["blink.cmp"] and not package.loaded["blink.cmp"])
    registered("snippet-tools.nvim", "pairs.nvim")
    contents({ "" })
    vim.bo.filetype = "lua"
    feed("i(<CR>x<Esc>")
    loaded("completion-tools.nvim")
    loaded("pairs.nvim")
    loaded("snippet-tools.nvim")
    assert(not plugins.LuaSnip and not package.loaded.luasnip)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(vim.deep_equal(lines, { "(", "  x", ")" }), "First insert newline pairing failed: " .. vim.inspect(lines))
    for _, provider in ipairs({ "blink-copilot", "blink-cmp-dictionary", "blink-cmp-spell", "colorful-menu.nvim" }) do
      assert(not plugins[provider], "Unadapted provider must stay absent: " .. provider)
    end
    -- Authentication/status share the completion plugin; no second AI plugin.
    assert(vim.fn.exists(":CompletionToolsCopilot") == 2)
    local notifications, notify = {}, vim.notify
    vim.notify = function(message)
      notifications[#notifications + 1] = message
    end
    vim.cmd("CompletionToolsCopilot status")
    vim.notify = notify
    assert(#notifications == 1)
    assert(not package.loaded["copilot.client"] and not package.loaded["copilot.api"])
    for _, client in ipairs(vim.lsp.get_clients()) do
      assert(client.name ~= "completion-tools-copilot", "Status must not start the server")
    end
  else
    error("Unknown lazy startup case: " .. tostring(case))
  end
  if vim.v.errmsg == "E31: No such mapping" or vim.v.errmsg == "E216: No such group or event: FileExplorer *" then
    vim.v.errmsg = ""
  end
  assert(vim.v.errmsg == "", vim.v.errmsg)
  assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
end

vim.api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    vim.defer_fn(function()
      local ok, err = xpcall(check, debug.traceback)
      local result = ok and ("Terminal lazy-loading checks passed: " .. vim.env.NVIM_STARTUP_CASE) or err
      vim.fn.writefile(vim.split(result, "\n", { plain = true }), vim.env.NVIM_STARTUP_RESULT)
      vim.cmd(ok and "quitall!" or "cquit 1")
    end, 50)
  end,
})
