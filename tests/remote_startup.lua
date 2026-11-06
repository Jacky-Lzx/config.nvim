vim.api.nvim_create_autocmd("User", {
  pattern = "ConfigReady",
  once = true,
  callback = function()
    vim.defer_fn(function()
      local ok, err = xpcall(function()
        local manager = require("config.plugins").manager
        local root = assert(vim.env.NVIM_PLUGIN_ROOT)
        local lock = require("plugin_tools.util").read_json(manager.lockfile)
        for id, package in pairs(manager.graph.packages) do
          assert(package.managed and package.dir == root .. "/" .. id, "Development path leaked: " .. id)
          assert(lock.plugins[id].source == package.source, id)
          local marker = require("plugin_tools.util").read_json(package.dir .. "/.git/plugin-tools-owner.json")
          assert(marker.commit == lock.plugins[id].commit and marker.source == package.source, id)
          if manager.graph.nodes[id].start then
            assert(manager.states[id].phase == "ready", id)
          end
        end
        for _, path in ipairs(vim.opt.rtp:get()) do
          assert(not path:find("/Github/nvim_plugins/", 1, true), "Development runtime leaked: " .. path)
        end
        assert(
          not package.loaded.completion_tools and not package.loaded["completion_tools.ui"],
          "Remote capability lookup imported the input engine"
        )
        for _, name in ipairs({ "completion_tools.bootstrap", "image_tools.bootstrap", "snippet_tools.bootstrap" }) do
          local frontend = require(name)
          assert(type(frontend.ensure) == "function", "Missing published API: " .. name)
          assert(frontend.ensure(), name)
          assert(debug.getinfo(frontend.ensure).source:find(root, 1, true), name)
        end
        assert(#_G.config_test_errors == 0, table.concat(_G.config_test_errors, "\n"))
        print("PASS: remote startup and first use (" .. vim.env.NVIM_TEST_SCENARIO .. ")")
      end, debug.traceback)
      if not ok then
        io.stderr:write(err .. "\n")
      end
      vim.cmd(ok and "qa!" or "cquit 1")
    end, 30)
  end,
})
