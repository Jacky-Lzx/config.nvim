-- Invoked by tests/tui.py so Lazy's real UIEnter -> VeryLazy path runs.
local temp = assert(vim.env.NVIM_TEST_TMP)
local plugins = require("lazy.core.config").plugins
local function unloaded(...)
  for _, name in ipairs({ ... }) do
    assert(plugins[name] and not plugins[name]._.loaded, "Unexpectedly loaded " .. name)
  end
end
local function loaded(name)
  assert(plugins[name] and plugins[name]._.loaded, "Did not load " .. name)
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
  assert(vim.g.did_very_lazy, "This check must run after the real VeryLazy event")
  unloaded(
    "nvim-dap",
    "nvim-dap-view",
    "nvim-tree.lua",
    "nvim-lsp-file-operations",
    "overseer.nvim",
    "conform.nvim",
    "LuaSnip",
    "pairs.nvim",
    "copilot.lua",
    "blink-copilot",
    "blink-cmp-dictionary",
    "blink-cmp-spell",
    "colorful-menu.nvim",
    "mini.ai",
    "mini.align",
    "mini.operators",
    "nvim-hlslens",
    "todo-comments.nvim",
    "nvim-scrollbar",
    "nvim-highlight-colors"
  )
  assert(not plugins["mini.surround"] and not plugins["rainbow-delimiters.nvim"])
  assert(not package.loaded["tex-tools"], "TeX tools loaded without a TeX buffer")
  assert(not plugins.vimtex and not plugins["nvim-texlabconfig"])
  for _, command in ipairs({ "NvimTreeToggle", "OverseerToggle", "CodeCompanionChat", "LuaSnipEdit", "Copilot" }) do
    assert(vim.fn.exists(":" .. command) == 2, "Missing cold command: " .. command)
  end

  local case = vim.env.NVIM_LAZY_CASE
  -- Some installed plugins use silent! cleanup for absent legacy autocmds and
  -- dictionary watchers. These leave v:errmsg without reporting an error.
  vim.v.errmsg = ""
  if case == "boundaries" or case == "boundaries_lfo" then
    -- First-save opt-out must not initialize Conform or trim whitespace.
    feed(" tf")
    assert(vim.g.enable_autoformat == false)
    unloaded("conform.nvim")
    vim.cmd.edit(temp .. "/lazy-save.txt")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "keep spaces   " })
    vim.cmd.write()
    loaded("conform.nvim")
    assert(vim.api.nvim_get_current_line() == "keep spaces   ", "First save ignored the formatting opt-out")
    feed(" tf")
    vim.cmd.write()
    assert(vim.api.nvim_get_current_line() == "keep spaces", "Second toggle did not restore formatting")

    vim.fn.mkdir(temp .. "/lazy-cargo", "p")
    vim.cmd.edit(temp .. "/lazy-cargo/Cargo.toml")
    loaded("crates.nvim")
    loaded("pairs.nvim") -- Reading/creating a file enables rainbow before InsertEnter.
    assert(require("pairs.rainbow").status().enabled)
    unloaded("nvim-dap", "nvim-tree.lua", "LuaSnip", "copilot.lua", "nvim-hlslens")
    for _, extension in ipairs({ "cpp", "swift" }) do
      vim.cmd.edit(temp .. "/lazy-file." .. extension)
      unloaded("nvim-dap", "nvim-dap-view", "nvim-tree.lua")
    end
    vim.api.nvim_exec_autocmds("LspAttach", { buffer = 0, data = { client_id = 999999 } })
    unloaded("nvim-tree.lua", "nvim-lsp-file-operations", "nvim-dap")

    if case == "boundaries_lfo" then
      vim.cmd("LFO create " .. vim.fn.fnameescape(temp .. "/lfo-file-" .. vim.uv.os_getpid()))
      loaded("nvim-lsp-file-operations")
      unloaded("nvim-tree.lua")
    end
    -- Invoke the public command on the first use and verify tree event wiring.
    vim.cmd("NvimTreeToggle")
    loaded("nvim-tree.lua")
    loaded("nvim-lsp-file-operations")
    local renamed
    local get_clients = vim.lsp.get_clients
    vim.lsp.get_clients = function()
      return {
        {
          initialized = true,
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
    require("nvim-tree.events")._dispatch_node_renamed(temp .. "/old.txt", temp .. "/new.txt")
    vim.lsp.get_clients = get_clients
    assert(
      renamed and renamed.oldUri == vim.uri_from_fname(temp .. "/old.txt"),
      "First tree open missed rename notifications"
    )
    vim.cmd("NvimTreeClose")
    vim.cmd("OverseerToggle")
    loaded("overseer.nvim")
    vim.cmd("OverseerClose")
    feed(" b")
    loaded("nvim-dap")
    loaded("nvim-dap-view")
  elseif case == "editing" then
    contents({ "a=1", "long=2" })
    vim.fn.writefile({ "Running first alignment" }, vim.env.NVIM_LAZY_RESULT)
    feed("VjgA=")
    loaded("mini.align")
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(lines[1]:find("=", 1, true) == lines[2]:find("=", 1, true), vim.inspect(lines))
    contents({ "word" })
    vim.fn.writefile({ "Running first multiply" }, vim.env.NVIM_LAZY_RESULT)
    feed("gmm")
    loaded("mini.operators")
    assert(vim.api.nvim_buf_line_count(0) == 2, "First multiply key did not duplicate the line")
    contents({ "(word)" })
    vim.fn.writefile({ "Running first textobject" }, vim.env.NVIM_LAZY_RESULT)
    feed("di(")
    loaded("mini.ai")
    assert(vim.api.nvim_get_current_line() == "()", "First textobject key did not operate")
    contents({ "(word)" })
    vim.fn.writefile({ "Running first surround" }, vim.env.NVIM_LAZY_RESULT)
    feed("sd)")
    loaded("pairs.nvim")
    assert(require("pairs").status().surround.enabled)
    assert(#require("pairs").status().surround.conflicts == 0)
    assert(vim.api.nvim_get_current_line() == "word", "First surround key did not operate")
    contents({ "match match" })
    vim.fn.writefile({ "Running first search" }, vim.env.NVIM_LAZY_RESULT)
    feed("/match<CR>")
    loaded("nvim-hlslens")
    assert(require("scrollbar.config").get().handlers.search, "First search did not enable scrollbar integration")
  elseif case == "completion" then
    feed(":<Esc>")
    loaded("blink.cmp")
    assert(
      vim.wait(1000, function()
        return package.loaded["blink.cmp.completion"] ~= nil
      end, 10),
      "Completion setup did not finish"
    )
    unloaded("LuaSnip", "pairs.nvim", "copilot.lua", "blink-copilot", "blink-cmp-dictionary", "blink-cmp-spell")
    contents({ "" })
    vim.bo.filetype = "lua"
    feed("i(<CR>x<Esc>")
    loaded("pairs.nvim")
    loaded("LuaSnip")
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(vim.deep_equal(lines, { "(", "  x", ")" }), "First insert newline pairing failed: " .. vim.inspect(lines))
    local sources = require("blink.cmp.sources.lib")
    for _, provider in ipairs({ "snippets", "dictionary", "spell", "copilot" }) do
      assert(sources.get_provider_by_id(provider), "Could not initialize provider " .. provider)
    end
    loaded("blink-cmp-dictionary")
    loaded("blink-cmp-spell")
    loaded("blink-copilot")
    loaded("copilot.lua")
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
  pattern = "VeryLazy",
  once = true,
  callback = function()
    vim.defer_fn(function()
      local ok, err = xpcall(check, debug.traceback)
      local result = ok and ("Terminal lazy-loading checks passed: " .. vim.env.NVIM_LAZY_CASE) or err
      vim.fn.writefile(vim.split(result, "\n", { plain = true }), vim.env.NVIM_LAZY_RESULT)
      vim.cmd(ok and "quitall!" or "cquit 1")
    end, 50)
  end,
})
