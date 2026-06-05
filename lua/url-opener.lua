-- Platform-aware URL opener. Spawns the OS default handler (xdg-open / open
-- / cmd.exe start) detached so nvim doesn't track the child. Callers extract
-- the URL however they like (markdown link parsing, <cfile>, etc.) and pass
-- it in.

local M = {}

-- The OS default-handler command, as an argv list a URL or file path can be
-- appended to. Exposed (not just used internally by M.open) so other callers
-- that need the handler argv can reuse it: preview.nvim, for one, hands temp
-- files to the browser this way.
function M.cmd()
  if vim.fn.has('macunix') == 1 then
    return { 'open' }
  elseif vim.fn.has('win32') == 1 then
    return { 'cmd.exe', '/c', 'start', '""' }
  else
    return { 'xdg-open' }
  end
end

local opener = M.cmd

-- Open `url` with the platform handler, then notify. `label` customizes the
-- notification prefix ("Opening <label>: <url>"); defaults to "URL".
function M.open(url, label)
  vim.fn.jobstart(vim.list_extend(opener(), { url }), { detach = true })
  vim.notify('Opening ' .. (label or 'URL') .. ': ' .. url)
end

return M
