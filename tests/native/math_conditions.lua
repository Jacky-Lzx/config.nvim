vim.opt.rtp:prepend(assert(vim.env.NVIM_CONFIG_ROOT))
local calls, result = {}, true
package.loaded["tex-tools"] = {
  in_math = function()
    calls[#calls + 1] = "tex"
    return result
  end,
  document_class = function()
    return "ctexbeamer"
  end,
  in_environment = function(names)
    calls[#calls + 1] = names
    return result
  end,
}
package.loaded.markdown_tools = {
  in_math = function()
    calls[#calls + 1] = "markdown"
    return result
  end,
}
local conditions = require("snippet_collections.tex.context").fn
vim.bo.filetype = "tex"
assert(conditions.in_math() and calls[#calls] == "tex")
assert(conditions.in_beamer())
assert(conditions.in_align() and vim.deep_equal(calls[#calls], { "align", "align*", "aligned" }))
assert(conditions.in_figure() and conditions.in_bullets())
result = false
assert(not conditions.in_math() and not conditions.in_figure())
vim.bo.filetype = "plaintex"
assert(not conditions.in_math() and calls[#calls] == "tex")
result = true
vim.bo.filetype = "markdown"
assert(conditions.in_math() and calls[#calls] == "markdown")
assert(not conditions.in_beamer() and not conditions.in_align() and not conditions.is_latex())
vim.bo.filetype = "lua"
assert(not conditions.in_math())
assert(vim.fn.exists(":DebugSileMath") == 0 and vim.fn.exists(":CheckCursorMathZone") == 0)
print("Snippet conditions dispatch to language owners without registering debug commands")
