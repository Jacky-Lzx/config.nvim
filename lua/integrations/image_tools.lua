-- Activate automatic previews without initializing image-tools for plain text.
-- These are conservative hints, not reference parsers: image-tools still owns
-- syntax exclusions, multiline references, path validation and rendering.
local M = {}
local api = vim.api
local automatic, markdown_math, activate, group
local watched = {}
local pending = {}
local hints = {
  markdown = function(line)
    return line:find("![", 1, true)
      or markdown_math
        and (line:find("$", 1, true) or line:find("\\(", 1, true) or line:find("\\[", 1, true) or line:find(
          "\\begin",
          1,
          true
        ))
  end,
  tex = function(line)
    return line:find("\\includegraphics", 1, true)
  end,
  typst = function(line)
    return line:find("%f[%w_]image%s*%(") or line:find("%f[%w_]image%s*$")
  end,
  html = function(line)
    return line:lower():find("<img%f[^%w_]")
  end,
}
hints.plaintex, hints.latex = hints.tex, hints.tex

local function loaded()
  return package.loaded.image_tools
end

local function candidate(buf, first, last)
  if
    not automatic
    or loaded()
    or not api.nvim_buf_is_valid(buf)
    or vim.bo[buf].buftype ~= ""
    or #vim.fn.win_findbuf(buf) == 0
  then
    return false
  end
  local hint = hints[vim.bo[buf].filetype]
  if not hint then
    return false
  end
  last = last or api.nvim_buf_line_count(buf)
  -- Bound each allocation, including for a newly opened large document.
  for row = first or 0, last - 1, 256 do
    for _, line in ipairs(api.nvim_buf_get_lines(buf, row, math.min(row + 256, last), false)) do
      if hint(line) then
        return true
      end
    end
  end
  return false
end

local function request(buf)
  if pending[buf] then
    return
  end
  pending[buf] = true
  -- Buffer callbacks run under textlock. Recheck after scheduling so a deleted
  -- candidate, closed buffer or disabled automatic preview cannot activate us.
  vim.schedule(function()
    pending[buf] = nil
    if candidate(buf) then
      activate()
    end
  end)
end

local function watch(buf)
  if not automatic or loaded() or not api.nvim_buf_is_loaded(buf) or not hints[vim.bo[buf].filetype] then
    return
  end
  if not watched[buf] then
    watched[buf] = api.nvim_buf_attach(buf, false, {
      on_lines = function(_, changed, _, first, _, last)
        if loaded() then
          watched[changed] = nil
          return true
        end
        -- Scan changed lines only; ordinary typing never rescans the document.
        if candidate(changed, first, last) then
          request(changed)
        end
      end,
      on_reload = function(_, changed)
        if loaded() then
          watched[changed] = nil
          return true
        end
        if candidate(changed) then
          request(changed)
        end
      end,
      on_detach = function(_, changed)
        watched[changed] = nil
      end,
    })
  end
  if candidate(buf) then
    request(buf)
  end
end

local function tex()
  if vim.tbl_contains({ "tex", "plaintex", "latex" }, vim.bo.filetype) and require("languages").is_enabled("latex") then
    return require("tex-tools")
  end
end

function M.preview()
  local tools = tex()
  if tools and tools.formula_at() then
    return tools.preview_formula()
  end
  return require("image_tools").hover()
end

function M.enabled()
  local image = loaded()
  if image then
    return image.status().auto_preview
  end
  return automatic
end

function M.toggle()
  local image = loaded()
  if image then
    automatic = image.toggle()
  else
    automatic = not automatic
  end
  local tools = tex()
  if tools and tools.formula_info().enabled ~= automatic then
    tools.toggle_formula_preview()
  end
  if automatic and not image then
    for _, buf in ipairs(api.nvim_list_bufs()) do
      watch(buf)
    end
  end
  return automatic
end

-- Apply a toggle made before the first image command/API request.
function M.options(opts)
  return vim.tbl_extend("force", opts, { auto_preview = automatic })
end

function M.configured()
  if group then
    api.nvim_del_augroup_by_id(group)
    group = nil
  end
end

function M.setup(opts, loader)
  automatic, activate = opts.auto_preview ~= false, loader
  markdown_math = not (type(opts.math) == "table" and opts.math.enabled == false)
  group = api.nvim_create_augroup("ConfigImageActivation", { clear = true })
  api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    group = group,
    callback = function(event)
      watch(event.buf)
    end,
  })
  -- Native mappings must select the feature before requesting a provider. A
  -- Lazy keys proxy would load image-tools even for formula detection/toggle-off.
  vim.keymap.set("n", "<leader>si", M.preview, { desc = "[Image] Preview image or formula on current line" })
  vim.keymap.set("n", "<leader>ui", M.toggle, { desc = "[Image] Toggle automatic preview" })
  require("keymap_tools").register("image-tools.toggle", {
    toggles = { { keys = "<leader>ui", name = "Automatic image preview", get = M.enabled } },
  })
  for _, buf in ipairs(api.nvim_list_bufs()) do
    watch(buf)
  end
end

return M
