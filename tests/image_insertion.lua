-- Run after image_preview.lua has loaded the real local plugin and configuration.
local image = require("image_tools")
local plugin = require("lazy.core.config").plugins["image-tools.nvim"].dir
local fixture = plugin .. "/tests/fixtures/fixture.png"
local directory = vim.fn.tempname() .. "-insertion"
vim.fn.mkdir(directory .. "/chapters", "p")
local old_cwd = vim.fn.getcwd()
vim.api.nvim_set_current_dir(directory)
directory = vim.fn.getcwd()
local original_insert, original_paste, original_pick = image.insert, image.paste, image.pick
local backend = require("image_tools.workflow.clipboard_backend")
local detect, read = backend.detect, backend.read
local select, input = vim.ui.select, vim.ui.input
local done, failure, paths, reads
local function complete(err, result)
  failure, paths, done = err, result, true
end
image.insert = function(source, opts)
  return original_insert(source, opts, complete)
end
image.paste = function(opts)
  return original_paste(opts, complete)
end
backend.detect = function()
  return { name = "fixture", executable = "fixture" }
end
backend.read = function(_, output, _, callback)
  reads = (reads or 0) + 1
  assert(vim.uv.fs_copyfile(fixture, output))
  vim.schedule(function()
    callback()
  end)
  return function() end
end
local function document(ft, extension, text)
  vim.cmd("stopinsert")
  vim.cmd("%bwipeout!")
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_name(buf, directory .. "/chapters/example." .. extension)
  vim.bo[buf].filetype = ft
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text or "" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  done, failure, paths = false, nil, nil
  return buf
end
local function wait()
  assert(
    vim.wait(15000, function()
      return done
    end),
    "Image insertion timed out"
  )
  assert(not failure, failure)
end
local function key(suffix)
  local mapping = vim.fn.maparg(vim.g.mapleader .. suffix, "n", false, true)
  assert(mapping.callback, "Missing image mapping: " .. suffix)
  mapping.callback()
end
local function text()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end
local function cursor(row, col)
  assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { row, col }), "Incorrect description/caption cursor")
end
local function check_paste(ft, extension, expected, row, col)
  local buf = document(ft, extension)
  vim.cmd("ImageInsert")
  wait()
  local path = assert(paths[1])
  assert(
    vim.fs.dirname(path) == directory .. "/Figures",
    "Paste must save in cwd/Figures: " .. path .. " vs " .. directory
  )
  assert(vim.fs.basename(path):match("^%d%d%d%d%-%d%d%-%d%d_%d%d%-%d%d%-%d%d"), "Timestamp name missing")
  assert(path:sub(-#expected) == expected, "Clipboard encoding incompatible with document")
  if col then
    cursor(row, col)
  end
  return text(), buf
end
local md = check_paste("markdown", "md", ".avif", 1, 2)
assert(md:match("^!%[%]%(%../Figures/.*%.avif%)$"), md)
local tex = check_paste("tex", "tex", ".png", 4, #"  \\caption{")
assert(tex:find("\\begin{figure}[ht]", 1, true) and tex:find("width=0.8\\linewidth", 1, true), tex)
assert(tex:find("{../Figures/", 1, true) and tex:find("\\label{fig:", 1, true), tex)
local typ = check_paste("typst", "typ", ".png", 3, #"  caption: [")
assert(typ:find('#figure(\n  image("../Figures/', 1, true) and typ:find("width: 80%)", 1, true), typ)
local html = check_paste("html", "html", ".avif", 1, nil) -- Cursor depends on generated path length.
assert(html:match('^<img src="../Figures/.*%.avif" alt="" />$'), html)
cursor(1, assert(html:find('alt="', 1, true)) + 4)

-- Inline strategies must respect UTF-8 byte boundaries as well as line placement.
for _, case in ipairs({ { "pI", { "中x", "!" } }, { "PI", { "!", "中x" } }, { "pi", { "中!" } }, { "Pi", { "!" } } }) do
  document("markdown", "md", "中x")
  key(case[1])
  wait()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, prefix in ipairs(case[2]) do
    assert(lines[i]:sub(1, #prefix) == prefix, "Wrong paste strategy: " .. case[1])
  end
  vim.cmd("bwipeout!")
end

-- Verify actual menu filtering, filename input, and PNG/JPEG encoding; never read the desktop clipboard.
for _, ft in ipairs({ "markdown", "tex" }) do
  document(ft, ft == "tex" and "tex" or "md")
  local options
  vim.ui.select = function(items, _, callback)
    options = items
    callback(items[2])
  end
  vim.ui.input = function(opts, callback)
    assert(opts.default:match("^%d%d%d%d%-%d%d%-%d%d_"), "Filename prompt must suggest timestamp")
    callback("chosen")
  end
  key("pC")
  wait()
  assert(#options == (ft == "tex" and 3 or 5), "Formats must be filtered for the document")
  assert(paths[1]:match("/chosen%-?%d*%.jpg$"), "JPEG menu choice must publish a real .jpg")
  local fd = assert(vim.uv.fs_open(paths[1], "r", 0))
  assert(vim.uv.fs_read(fd, 2, 0) == "\255\216", "JPEG extension must match encoded bytes")
  vim.uv.fs_close(fd)
  vim.cmd("bwipeout!")
end

-- The file picker and :ImageInsert path must reference existing files without copying.
local source = directory .. "/outside (100%).png"
assert(vim.uv.fs_copyfile(fixture, source))
document("markdown", "md")
local command_source = directory .. "/source.png"
assert(vim.uv.fs_copyfile(fixture, command_source))
vim.cmd.ImageInsert(command_source)
wait()
assert(paths[1] == command_source, "Explicit :ImageInsert path must reference the source")
document("markdown", "md")
image.insert(source, { mode = "reference" })
wait()
assert(paths[1] == source, "Explicit :ImageInsert path must reference the source")
assert(text() == "![](../outside%20%28100%25%29.png)", text())
vim.cmd("bwipeout!")

local snacks = require("snacks")
local picker_files = snacks.picker.files
local picker_config, picker
snacks.picker.files = function(config)
  picker_config = config
  picker = {
    selected = function()
      return { { file = source }, { file = command_source } }
    end,
    close = function(self)
      config.on_close(self)
    end,
  }
  return picker
end
image.pick = function(opts)
  return original_pick(opts, complete)
end
document("markdown", "md", "before")
key("pc")
picker_config.actions.confirm(picker)
wait()
assert(vim.deep_equal(paths, { source, command_source }), "Picker must reference selected sources in order")
assert(text() == "before\n![](../outside%20%28100%25%29.png)\n![](../source.png)", text())
cursor(2, 2)
assert(not vim.uv.fs_stat(directory .. "/Figures/source.png"), "Picker must not copy sources")
image.pick, snacks.picker.files = original_pick, picker_files

-- Cancelling the process menu must leave the document and clipboard untouched.
document("markdown", "md", "unchanged")
local before_reads = reads
vim.ui.select = function(_, _, callback)
  callback(nil)
end
key("pC")
assert(done and failure == "Cancelled" and reads == before_reads and text() == "unchanged")

-- Explicit import remains available and retains the source basename.
document("markdown", "md")
vim.ui.input = function(_, callback)
  callback(source)
end
key("pf")
wait()
assert(paths[1] == directory .. "/Figures/outside (100%).png", "Import must copy and retain the filename")

image.insert, image.paste, image.pick = original_insert, original_paste, original_pick
backend.detect, backend.read = detect, read
vim.ui.select, vim.ui.input = select, input
vim.cmd("stopinsert")
vim.cmd("%bwipeout!")
vim.api.nvim_set_current_dir(old_cwd)
vim.fn.delete(directory, "rf")
print("image_insertion: configured templates, clipboard conversion, paths, commands and mappings passed")
