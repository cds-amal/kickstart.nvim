-- Display layer for rustaceanvim's quickfix test executor (wired up in
-- plugins/rustaceanvim.lua as tools.test_executor). The stock executor parses
-- cargo's output through 'errorformat', which is what makes panics, compiler
-- messages, and dbg! lines jumpable; the price is the default window
-- rendering, where every line that didn't parse shows up as `|| text` in a
-- single color. Two fixes live here: a quickfixtextfunc that renders located
-- entries as `path:line: text` and passes everything else through verbatim,
-- and window-local matches that color verdicts, status lines, and panics
-- roughly the way cargo's own terminal output does.
--
-- Volume is the lever this module does not touch: a whole-suite run is
-- thousands of lines however it renders, where a test resolved at the
-- cursor is thirty ("running 1 test"). For pruning a big list in place,
-- cfilter is loaded below: `:Cfilter! /ok$/` drops every passing line.

local M = {}

-- The executor titles its lists 'cargo'; only those get the custom
-- rendering. Every other quickfix list keeps the default format.
local function is_cargo_list(id)
  return vim.fn.getqflist({ id = id, title = 0 }).title == 'cargo'
end

function M.qf_text(info)
  if info.quickfix ~= 1 or not is_cargo_list(info.id) then
    return {} -- empty means: fall back to the default rendering
  end
  local items = vim.fn.getqflist({ id = info.id, items = 0 }).items
  local lines = {}
  for i = info.start_idx, info.end_idx do
    local item = items[i]
    if item.valid == 1 and item.bufnr > 0 then
      local path = vim.fn.fnamemodify(vim.fn.bufname(item.bufnr), ':.')
      -- Panic entries are multiline (%E location + %Z message join with an
      -- embedded newline); a qftf must return single-line strings.
      local text = item.text:gsub('%s*\n%s*', ' '):gsub('^%s+', '')
      lines[#lines + 1] = ('%s:%d: %s'):format(path, item.lnum, text)
    else
      -- An empty string from a qftf makes vim fall back to the default
      -- format (`|| `), so blank output lines render as a space instead.
      lines[#lines + 1] = item.text == '' and ' ' or item.text
    end
  end
  return lines
end

-- { group, default link, vim regex }. Patterns match the rendering above,
-- so located entries are matched as `path:line:`, never as `|| ...`.
local MATCHES = {
  -- per-test verdicts
  { 'CargoQfOk', 'DiagnosticOk', [[\v \.\.\. ok$]] },
  { 'CargoQfFailed', 'DiagnosticError', [[\v \.\.\. FAILED$]] },
  { 'CargoQfIgnored', 'Comment', [[\v \.\.\. ignored.*$]] },
  -- run structure and summary
  { 'CargoQfTitle', 'Title', [[\v^running \d+ tests?$]] },
  { 'CargoQfOk', 'DiagnosticOk', [[\v^test result: ok\..*$]] },
  { 'CargoQfFailed', 'DiagnosticError', [[\v^test result: FAILED\..*$]] },
  { 'CargoQfFailed', 'DiagnosticError', [[\v^failures:$]] },
  -- cargo and rustc chatter
  { 'CargoQfStatus', 'Function', [[\v^\s*(Compiling|Checking|Finished|Running|Blocking|Downloaded|Fresh|Doc-tests)>]] },
  -- `.{-}` rather than a `[^]]` collection: the latter embeds `]]` and
  -- terminates the long-bracket Lua string early.
  { 'CargoQfWarn', 'DiagnosticWarn', [[\v^warning(\[.{-}\])?:]] },
  { 'CargoQfError', 'DiagnosticError', [[\v^error(\[.{-}\])?:]] },
  { 'CargoQfError', 'DiagnosticError', [[\vpanicked at]] },
  -- the path:line: prefix qf_text puts on located entries
  { 'CargoQfFile', 'qfFileName', [[\v^[^ |]+:\d+:]] },
}

-- Style the quickfix window. Highlight links are (re)applied here rather
-- than once at startup so a colorscheme switch heals on the next run.
-- clearmatches keeps reruns idempotent; the quickfix window has no other
-- matches worth preserving.
function M.decorate()
  local winid = vim.fn.getqflist({ winid = 0 }).winid
  if winid == 0 then
    return
  end
  vim.fn.clearmatches(winid)
  for _, m in ipairs(MATCHES) do
    vim.api.nvim_set_hl(0, m[1], { link = m[2], default = true })
    vim.fn.matchadd(m[1], m[3], 10, -1, { window = winid })
  end
end

-- Cargo-tailored errorformat, passed per-append via setqflist's `efm` field
-- so the global option is untouched. Single-line patterns only: every output
-- line still lands in the list (unmatched ones as plain text); these decide
-- which lines carry a jumpable location. The default errorformat gets this
-- wrong in a sneaky way: it folds the `[` of a dbg! line (and the `-->` of a
-- compiler diagnostic) into %f, allocating a phantom buffer named
-- `[crates/...` that jumps to an empty scratch instead of the file.
local EFM = table.concat({
  '[%f:%l:%c] %m', -- dbg!() output
  -- A panic prints its location and its message on consecutive lines; the
  -- %E/%Z pair folds them into one entry carrying both.
  "%Ethread '%.%#' panicked at %f:%l:%c:",
  '%Z%m',
  -- Compiler diagnostic arrows. scanf-style %*[ ] for the indent: a literal
  -- leading space is trimmed after the comma separator, so ` %#-->` works
  -- alone but silently stops matching once any pattern precedes it.
  '%*[ ]--> %f:%l:%c',
  '%f:%l:%c: %m',
  '%f:%l: %m',
}, ',')

-- Drop-in for tools.test_executor. Same shape as rustaceanvim's stock
-- quickfix executor (copen, jump back, fresh titled list, append the whole
-- stdout+stderr blob when the process exits) plus the EFM parse and the
-- window styling. Matches live on the window, so decorating before the
-- async output lands is fine. Appends target the captured list id, so a
-- quickfix list created mid-run doesn't receive test output.
M.executor = {
  execute_command = function(command, args, cwd, _)
    vim.cmd 'copen'
    vim.cmd.wincmd 'p'
    vim.fn.setqflist({}, ' ', { title = 'cargo' })
    local id = vim.fn.getqflist({ id = 0 }).id
    M.decorate()
    local cmd = vim.list_extend({ command }, args)
    vim.system(
      cmd,
      cwd and { cwd = cwd } or {},
      vim.schedule_wrap(function(sc)
        local data = (sc.stdout or '') .. '\n' .. (sc.stderr or '')
        vim.fn.setqflist({}, 'a', { id = id, lines = vim.split(data, '\n'), efm = EFM })
        if vim.bo.buftype ~= 'quickfix' then
          vim.cmd 'cbottom'
        end
      end)
    )
  end,
}

vim.o.quickfixtextfunc = "v:lua.require'cargo-quickfix'.qf_text"

-- Ships with the nvim runtime; gives :Cfilter/:Lfilter for pruning lists.
vim.cmd.packadd 'cfilter'

return M
