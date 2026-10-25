local M = {}

local skim_location = [=[
on run argv
  set thePath to POSIX path of ((POSIX file (item 1 of argv)) as alias)
  set pageNumber to (item 2 of argv) as integer
  set syncX to (item 3 of argv) as real
  set syncY to (item 4 of argv) as real
  set sourceFile to POSIX file (item 5 of argv)
  set sourceLine to (item 6 of argv) as integer
  tell application id "net.sourceforge.skim-app.skim"
    repeat 50 times
      set theDocs to documents whose path is thePath
      if (count of theDocs) > 0 then
        set theDoc to item 1 of theDocs
        if (count of pages of theDoc) >= pageNumber then
          set thePage to page pageNumber of theDoc
          set pageBounds to media bounds of thePage
          set pdfX to (item 1 of pageBounds) + syncX
          set pdfY to (item 2 of pageBounds) - syncY
          repeat 10 times
            go theDoc to thePage at {pdfX, pdfY}
            delay 0.1
            go theDoc to thePage at {pdfX, pdfY}
            delay 0.1
            if (index of current page of theDoc) is pageNumber then
              -- Let Skim draw its native, temporary SyncTeX indicator.
              set has reading bar of theDoc to false
              go theDoc to TeX line sourceLine from sourceFile
              return pageNumber
            end if
          end repeat
          error "Skim did not finish positioning the PDF"
        end if
      end if
      delay 0.1
    end repeat
  end tell
  error "Skim did not finish opening the PDF"
end run

]=]

local function notify(message)
  vim.notify(message, vim.log.levels.ERROR, { title = "latex-lsp" })
end

local function run(command, callback)
  local ok, error = pcall(
    vim.system,
    command,
    { text = true, timeout = 7000 },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        local message = vim.trim(result.stderr or "")
        notify(message ~= "" and message or ("PDF viewer failed (exit " .. result.code .. ")"))
      elseif callback then
        callback()
      end
    end)
  )
  if not ok then
    notify(tostring(error))
  end
end

function M.open(result, params)
  local location = result.locations and result.locations[1]
  if not location then
    vim.notify("No SyncTeX location for this source line", vim.log.levels.WARN, { title = "latex-lsp" })
    return
  end
  local platform = require("utils.platform")
  local skim, zathura = platform.skim_displayline(), platform.executable("zathura")
  local pdf, source = vim.uri_to_fname(result.pdfUri), vim.uri_to_fname(params.textDocument.uri)
  local line = tostring(params.position.line + 1)
  local app = skim and skim:match("^(.*%.app)/Contents/SharedSupport/displayline$")
  if app then
    -- LaunchServices opens the document without waiting for Skim's first
    -- AppleScript open reply. Keep the editor focused with background open.
    -- Use the mapping already calculated by the LSP;
    -- Skim's own SyncTeX state may not be ready on its first launch.
    run({ "/usr/bin/open", "-g", "-a", app, pdf }, function()
      run({
        "/usr/bin/osascript",
        "-e",
        skim_location,
        pdf,
        tostring(location.page),
        tostring(location.x),
        tostring(location.y),
        source,
        line,
      })
    end)
  elseif skim then
    run({ skim, "-g", line, pdf, source })
  elseif zathura then
    run({ zathura, "--synctex-forward", line .. ":1:" .. source, pdf })
  else
    vim.notify("Install Skim or Zathura for forward search", vim.log.levels.WARN)
  end
end

-- Keep an early keypress until the native client has sent didOpen.
local pending = {}

function M.request(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  -- latex-lsp advertises UTF-16. Capture the position when the key is pressed.
  local params = vim.lsp.util.make_position_params(0, "utf-16")
  local function ready_client()
    for _, client in ipairs(vim.lsp.get_clients({ name = "latex_lsp", bufnr = bufnr })) do
      if client.initialized then
        return client
      end
    end
  end
  local function send(client, position)
    local sent = client:request("workspace/executeCommand", {
      command = "latex.forwardSearch",
      arguments = { { uri = position.textDocument.uri, position = position.position } },
    }, function(err, result)
      if err then
        notify(err.message)
      elseif result then
        M.open(result, position)
      end
    end, bufnr)
    if not sent then
      notify("latex-lsp could not accept the forward-search request")
    end
  end
  local client = ready_client()
  if client then
    if pending[bufnr] then
      pending[bufnr].cancel()
    end
    send(client, params)
    return
  end
  if pending[bufnr] then
    pending[bufnr].params = params
    return
  end
  local request = { params = params }
  pending[bufnr] = request
  request.cancel = function()
    pending[bufnr] = nil
    vim.api.nvim_del_autocmd(request.autocmd)
  end
  request.autocmd = vim.api.nvim_create_autocmd({ "LspAttach", "BufWipeout" }, {
    buffer = bufnr,
    callback = function(event)
      if event.event == "BufWipeout" then
        request.cancel()
      else
        local attached = ready_client()
        if attached then
          request.cancel()
          send(attached, request.params)
        end
      end
    end,
  })
  vim.defer_fn(function()
    if pending[bufnr] == request then
      request.cancel()
      notify("latex-lsp did not attach; forward search was cancelled")
    end
  end, 10000)
end

return M
