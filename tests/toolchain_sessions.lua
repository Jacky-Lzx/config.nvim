-- Preserve real tool activation and lease handling, but keep lease files out of
-- the host's installed tool store. Call before loading toolchain in a test.
local sessions = require("utils.platform").dev_plugin_root() .. "/toolchain-tools.nvim/lua/toolchain/tool_sessions.lua"
if vim.fn.filereadable(sessions) == 1 then
  _G.config_test_toolchain_sessions = vim.fn.stdpath("state") .. "/toolchain-test-sessions"
  package.preload["toolchain.tool_sessions"] = function()
    local module = dofile(sessions)
    local record, protection = module.record, module.protection
    local function location(store)
      return _G.config_test_toolchain_sessions .. "/" .. vim.fn.sha256(store)
    end
    module.record = function(store, roots)
      local isolated, mapped = location(store), {}
      for _, root in ipairs(roots) do
        assert(vim.startswith(root, store .. "/versions/"), "Session root is outside the tool store")
        mapped[#mapped + 1] = isolated .. root:sub(#store + 1)
      end
      return record(isolated, mapped)
    end
    module.protection = function(store)
      return protection(location(store))
    end
    return module
  end
end
