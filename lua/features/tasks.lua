-- Personal task workflows; task-tools owns processes, output and UI.
local M = {}

local function tools()
  return require("task_tools")
end

function M.definitions(ctx)
  if ctx.filetype ~= "markdown" or ctx.file == "" then
    return {}
  end
  return {
    {
      name = "Markdown: PDF",
      cmd = {
        "pandoc",
        ctx.file,
        "-o",
        ctx.file:gsub("%.[^/.]+$", "") .. ".pdf",
        "--pdf-engine=xelatex",
        "-V",
        "CJKmainfont="
          .. (
            vim.env.NVIM_MARKDOWN_PDF_FONT
            or (require("utils.platform").is("macos") and "Heiti SC" or "Noto Sans CJK SC")
          ),
      },
      cwd = vim.fs.dirname(ctx.file),
    },
  }
end

function M.prompt()
  return tools().manual.prompt({ default = "make", prompt = "Build command: " })
end
for _, method in ipairs({ "stop", "output", "quickfix" }) do
  M[method] = function()
    return tools().manual[method]()
  end
end
function M.rerun()
  return tools().manual.rerun({ default = "make", prompt = "Build command: " })
end
function M.run_file()
  return tools().run_file()
end

local function enabled()
  return require("config.context").current().selection.features.tasks
end

function M.session_path(name)
  return vim.fn.stdpath("state") .. "/task-tools/sessions/" .. vim.fn.sha256(name) .. ".json"
end

function M.save_session(name)
  local t = package.loaded.task_tools
  if not enabled() or not t or #t.list() == 0 then
    return
  end
  local path = M.session_path(name)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  t.save(path)
end

function M.restore_session(name)
  if not enabled() then
    return
  end
  local path = M.session_path(name)
  if vim.uv.fs_stat(path) then
    tools().load(path)
  end
end

function M.delete_session(name)
  vim.fn.delete(M.session_path(name))
end

return M
