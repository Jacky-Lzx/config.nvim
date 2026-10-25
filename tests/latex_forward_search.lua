-- nvim --clean --headless -i NONE -l tests/latex_forward_search.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(debug.getinfo(1, "S").source:sub(2))))
vim.opt.runtimepath:prepend(root)
local calls, notifications, responses = {}, {}, {}
local skim = "/Applications/Skim.app/Contents/SharedSupport/displayline"
local zathura
package.loaded["utils.platform"] = {
  skim_displayline = function()
    return skim
  end,
  executable = function()
    return zathura
  end,
}
vim.notify = function(message, level)
  notifications[#notifications + 1] = { message, level }
end
vim.system = function(command, options, callback)
  assert(options.text and options.timeout == 7000)
  calls[#calls + 1] = command
  local response = responses[#calls] or { code = 0, stderr = "" }
  if response.throw then
    error(response.throw)
  end
  callback(response)
end
local forward = require("languages.latex.forward_search")
local pdf = '/project/引号 " and spaces/paper.pdf'
local source = "/project/chapter.tex"
local params = { textDocument = { uri = vim.uri_from_fname(source) }, position = { line = 11, character = 0 } }
local result = { pdfUri = vim.uri_from_fname(pdf), locations = { { page = 3, x = 48.5, y = 323.75 } } }
local function settle()
  vim.wait(50, function()
    return false
  end, 5)
end
local function reset()
  calls, notifications, responses = {}, {}, {}
end
forward.open(result, params)
settle()
assert(#calls == 2 and #notifications == 0)
assert(vim.deep_equal(calls[1], { "/usr/bin/open", "-g", "-a", "/Applications/Skim.app", pdf }))
assert(calls[2][1] == "/usr/bin/osascript" and calls[2][2] == "-e")
assert(not calls[2][3]:find(pdf, 1, true), "PDF path was interpolated into AppleScript")
assert(not calls[2][3]:find(source, 1, true), "Source path was interpolated into AppleScript")
assert(vim.deep_equal(vim.list_slice(calls[2], 4), { pdf, "3", "48.5", "323.75", source, "12" }))
reset()
responses[1] = { code = 1, stderr = "Skim launch failed" }
forward.open(result, params)
settle()
assert(#calls == 1 and notifications[1][1] == "Skim launch failed")
reset()
responses[2] = { code = 1, stderr = "Skim did not finish opening the PDF" }
forward.open(result, params)
settle()
assert(#calls == 2 and notifications[1][1] == "Skim did not finish opening the PDF")
reset()
responses[1] = { throw = "Cannot spawn viewer" }
forward.open(result, params)
settle()
assert(#calls == 1 and notifications[1][1]:find("Cannot spawn viewer", 1, true))
reset()
forward.open({ pdfUri = result.pdfUri, locations = {} }, params)
assert(#calls == 0 and notifications[1][2] == vim.log.levels.WARN)
reset()
skim = "/custom/displayline"
forward.open(result, params)
settle()
assert(vim.deep_equal(calls[1], { skim, "-g", "12", pdf, source }))
reset()
skim = nil
zathura = "/usr/bin/zathura"
forward.open(result, params)
settle()
assert(vim.deep_equal(calls[1], { zathura, "--synctex-forward", "12:1:" .. source, pdf }))
reset()
zathura = nil
forward.open(result, params)
assert(#calls == 0 and notifications[1][2] == vim.log.levels.WARN)
print("LaTeX forward search passed: coordinates, path arguments, launch/query failures and viewer fallbacks")
