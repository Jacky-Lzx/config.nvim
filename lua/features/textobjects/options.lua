local M = {}

function M.get()
  local ai = require("mini.ai")
  local function syntax(captures)
    local spec = ai.gen_spec.treesitter(captures)
    return function(...)
      local ok, regions = pcall(spec, ...)
      return ok and regions or {}
    end
  end
  return {
    n_lines = 500,
    custom_textobjects = {
      o = syntax({
        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
      }),
      f = syntax({ a = "@function.outer", i = "@function.inner" }),
      c = syntax({ a = "@class.outer", i = "@class.inner" }),
      t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
      d = { "%f[%d]%d+" },
      e = {
        { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
        "^().*()$",
      },
      u = ai.gen_spec.function_call(),
      U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
    },
  }
end

return M
