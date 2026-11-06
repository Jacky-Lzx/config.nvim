-- Personal task workflows; task-tools owns processes, output and UI.
local M = {}
local manual

local function tools()
  return require("task_tools")
end
local function notify(message)
  vim.notify(message, vim.log.levels.WARN, { title = "Tasks" })
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
  local cwd = vim.fn.getcwd()
  vim.ui.input(
    { prompt = "Build command: ", default = manual and manual.spec.cmd or "make", completion = "shellcmd" },
    function(input)
      if not input or vim.trim(input) == "" then
        return
      end
      local spec = { cmd = input, cwd = cwd }
      local id = tools().run(spec)
      if id then
        manual = { id = id, spec = spec }
      end
    end
  )
end

function M.rerun()
  if not manual then
    return M.prompt()
  end
  local t = tools()
  local id
  if t.get(manual.id) then
    id = t.rerun(manual.id)
  else
    id = t.run(manual.spec)
  end
  if id then
    manual.id = id
  end
  return id
end

function M.stop()
  if manual then
    return tools().stop(manual.id)
  end
  notify("No manual build yet")
end

function M.output()
  if manual then
    return tools().show(manual.id)
  end
  notify("No manual build yet")
end

function M.quickfix()
  if manual then
    return tools().quickfix(manual.id)
  end
  notify("No manual build yet")
end

-- Parse argument quoting without invoking a shell or expanding variables.
function M.argv(text)
  local args, word, quote, escape, started = {}, "", nil, false, false
  for i = 1, #text do
    local char = text:sub(i, i)
    if escape then
      word, escape = word .. char, false
    elseif char == "\\" and quote ~= "'" then
      escape, started = true, true
    elseif quote then
      if char == quote then
        quote = nil
      else
        word = word .. char
      end
    elseif char == "'" or char == '"' then
      quote, started = char, true
    elseif char:match("%s") then
      if started then
        args[#args + 1], word, started = word, "", false
      end
    else
      word, started = word .. char, true
    end
  end
  if quote or escape then
    return nil, "Unclosed quote or trailing escape in arguments"
  end
  if started then
    args[#args + 1] = word
  end
  return args
end

function M.run_file()
  local buf = vim.api.nvim_get_current_buf()
  local file, ft = vim.api.nvim_buf_get_name(0), vim.bo.filetype
  if file == "" or vim.bo.buftype ~= "" or not vim.tbl_contains({ "python", "c", "cpp" }, ft) then
    notify("Run with arguments supports Python, C and C++ files")
    return
  end
  local cwd = vim.fs.dirname(file)
  local function arguments(executable)
    vim.ui.input({ prompt = "Arguments: " }, function(input)
      if input == nil then
        return
      end
      local args, err = M.argv(input)
      if not args then
        notify(err)
        return
      end
      local cmd
      if ft == "python" then
        cmd = { require("languages.python.interpreter").current({ buf = buf }), file }
      else
        cmd = { executable }
      end
      vim.list_extend(cmd, args)
      tools().run({
        name = ft == "python" and "Python: run with arguments" or "C/C++: run with arguments",
        cmd = cmd,
        cwd = cwd,
        env = ft == "python" and require("languages.python.interpreter").environment({ buf = buf }) or nil,
        mode = "terminal",
      }, { focus = true })
    end)
  end
  if ft == "python" then
    arguments()
  else
    local executable = file:gsub("%.[^/.]+$", "")
    if executable == file then
      executable = file .. ".out"
    end
    vim.ui.input({ prompt = "Executable: ", default = executable, completion = "file" }, function(input)
      if not input or vim.trim(input) == "" then
        return
      end
      input = vim.fs.normalize(input)
      if not vim.startswith(input, "/") and not input:match("^%a:[/\\]") then
        input = cwd .. "/" .. input
      end
      arguments(vim.fs.normalize(input))
    end)
  end
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
