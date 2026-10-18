-- Headless smoke test for lua/snippets/claudeprompt.lua. Run from the repo root:
--   nvim --headless -c 'luafile tests/claudeprompt-snippets-test.lua' -c 'cquit 1'
-- Needs the config loaded (lazy.nvim, LuaSnip), which `nvim -l` does not do.
-- The snippets read the clipboard through claudeprompt-snippets.read_clipboard,
-- a module field this test replaces, so the real clipboard is never read or
-- written and an uncaught error cannot leave a stray write behind.

local function fail(msg)
  io.stderr:write('FAIL: ' .. msg .. '\n')
  vim.cmd 'cquit 1'
end

local clipboard = ''
require('claudeprompt-snippets').read_clipboard = function()
  return clipboard
end

require('lazy').load { plugins = { 'LuaSnip' } }
local ls = require 'luasnip'

-- 0. The from_lua loader (scheduled by LuaSnip's config in lua/plugins/blink.lua)
-- must pick the file up for the `claudeprompt` filetype component on its own:
-- there is no registration step anywhere. Lazy loading is keyed on a buffer's
-- filetypes, so a buffer with the compound filetype has to exist first.
vim.cmd 'enew'
vim.bo.filetype = 'markdown.claudeprompt'
vim.wait(5000, function()
  return #ls.get_snippets 'claudeprompt' == 2
end)
if #ls.get_snippets 'claudeprompt' ~= 2 then
  fail('loader registered ' .. #ls.get_snippets 'claudeprompt' .. ' claudeprompt snippets, expected 2')
end

package.path = 'lua/?.lua;' .. package.path
local snips = dofile 'lua/snippets/claudeprompt.lua'

local triggers = {}
for _, snip in ipairs(snips) do
  triggers[#triggers + 1] = snip.trigger
end
if table.concat(triggers, ',') ~= 'prompt,anchor' then
  fail('expected triggers prompt,anchor; got ' .. table.concat(triggers, ','))
end

local function expect_lines(lines, want)
  for n, line in ipairs(want) do
    if lines[n] ~= line then
      fail(string.format('line %d: expected %q, got %q', n, line, tostring(lines[n])))
    end
  end
  if #lines ~= #want then
    fail(string.format('expected %d lines, got %d', #want, #lines))
  end
end

-- 1. `prompt` with a copy-with-context block on the clipboard.
clipboard = 'local servers = {}\n# lua/lsp.lua:12-13'
vim.cmd 'enew'
vim.bo.filetype = 'markdown.claudeprompt'
ls.snip_expand(snips[1])
expect_lines(vim.api.nvim_buf_get_lines(0, 0, -1, false), {
  '<prompt>',
  "<role>You are a careful engineer working in this repo. One rule: verify, don't guess. Read the code before claiming what it does; run the check before claiming it passes.</role>",
  '<mission>one sentence, one outcome</mission>',
  '<scope>',
  '  <in>what to touch</in>',
  '  <out>what to leave alone</out>',
  '</scope>',
  '<context>',
  "  decisions already made, so they don't get reopened",
  '</context>',
  '<code_anchors>',
  '  lua/lsp.lua:12-13',
  '  ```lua',
  '  local servers = {}',
  '  ```',
  '</code_anchors>',
  '<success_criteria>',
  "  how you'll know it worked, in checks you can run",
  '</success_criteria>',
  '<verification>the exact command to run</verification>',
  '</prompt>',
})
if not ls.jumpable(1) then
  fail 'prompt snippet is not jumpable after expansion'
end

-- 2. `prompt` with no header on the clipboard: the hint, on one line.
clipboard = 'nothing that looks like a header'
vim.cmd 'enew'
vim.bo.filetype = 'markdown.claudeprompt'
ls.snip_expand(snips[1])
local hint_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
if hint_lines[12] ~= '  real file:line for the files that matter, plus a pattern to copy' or hint_lines[13] ~= '</code_anchors>' then
  fail('hint fallback wrong: ' .. tostring(hint_lines[12]) .. ' / ' .. tostring(hint_lines[13]))
end

-- 3. `anchor` on an indented line. LuaSnip prefixes every continuation line
-- with the text before the trigger, so all lines must sit at column 2. The
-- `|` marker shows where the cursor was; in normal mode a cursor on blank
-- line "  " would clamp to column 1 and the indent would come out as one.
clipboard = 'local servers = {}\n# lua/lsp.lua:12-13'
vim.cmd 'enew'
vim.api.nvim_buf_set_lines(0, 0, -1, false, { '<code_anchors>', '  |', '</code_anchors>' })
vim.api.nvim_win_set_cursor(0, { 2, 2 })
ls.snip_expand(snips[2])
expect_lines(vim.api.nvim_buf_get_lines(0, 0, -1, false), {
  '<code_anchors>',
  '  lua/lsp.lua:12-13',
  '  ```lua',
  '  local servers = {}',
  '  ```|',
  '</code_anchors>',
})

print 'claudeprompt snippets: OK'
vim.cmd 'qa!'
