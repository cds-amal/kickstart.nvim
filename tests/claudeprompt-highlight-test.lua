-- Headless check that section bodies in a prompt buffer highlight as
-- markdown while plain html buffers are untouched. Run from the repo root:
--   nvim --headless -c 'luafile tests/claudeprompt-highlight-test.lua' -c 'cquit 1'
-- Fixture names must be hex after `claude-prompt-`, or the filetype pattern
-- in lua/filetypes.lua does not match.

local function fail(msg)
  io.stderr:write('FAIL: ' .. msg .. '\n')
  vim.cmd 'cquit 1'
end

local function captures_at(row, col)
  local names = {}
  for _, c in ipairs(vim.treesitter.get_captures_at_pos(0, row, col)) do
    names[#names + 1] = c.lang .. '/' .. c.capture
  end
  return table.concat(names, ' ')
end

local function has(caps, want)
  return caps:find(want, 1, true) ~= nil
end

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, 'p')

-- An html file FIRST, so its injections compile before any prompt buffer
-- exists; the predicate must already be registered or this buffer breaks.
local html = dir .. '/plain.html'
vim.fn.writefile({ '<div>', '- a bullet with `inline code`', '</div>' }, html)
vim.cmd('edit ' .. html)
-- An unregistered predicate makes this query fail to compile; the
-- ts-highlight autocmd swallows that in a pcall, so ask directly.
local ok, err = pcall(vim.treesitter.query.get, 'html', 'injections')
if not ok then
  fail('html injections do not compile: ' .. tostring(err))
end
vim.treesitter.get_parser(0):parse(true)
local html_caps = captures_at(1, 0)
if has(html_caps, 'markdown/') then
  fail('plain html got a markdown injection: ' .. html_caps)
end

-- A string parser has no buffer: treesitter hands predicates the source
-- string instead, and the claudeprompt? predicate must not throw on it
-- (plugins parse html and markdown strings for menus and previews).
local ok_str, err_str = pcall(function()
  vim.treesitter.get_string_parser('<div>hi</div>', 'html'):parse(true)
end)
if not ok_str then
  fail('html string parser throws through the predicate: ' .. tostring(err_str))
end

local prompt = dir .. '/claude-prompt-ab12.md'
vim.fn.writefile({
  '<prompt>',
  '<context>',
  '  - a bullet with `inline code`',
  '  - press `<leader>cy` then <C-y>',
  '</context>',
  '<code_anchors>',
  '  lua/lsp.lua:12-20',
  '  ```lua',
  '  local servers = {}',
  '  ```',
  '</code_anchors>',
  '</prompt>',
}, prompt)
vim.cmd('edit ' .. prompt)
if vim.bo.filetype ~= 'markdown.claudeprompt' then
  fail('filetype is ' .. vim.bo.filetype)
end
vim.treesitter.get_parser(0):parse(true)

local tag = captures_at(1, 1)
if not has(tag, 'html/tag') then
  fail('<context> is not an html tag: ' .. tag)
end
local bullet = captures_at(2, 2)
if not has(bullet, 'markdown/markup.list') then
  fail('bullet is not a markdown list item: ' .. bullet)
end
local inline = captures_at(2, 20)
if not has(inline, 'markdown_inline/markup.raw') then
  fail('inline code is not markdown raw: ' .. inline)
end
local bullet2 = captures_at(3, 2)
if not has(bullet2, 'markdown/markup.list') then
  fail('bullet after an angle-bracket token lost list highlighting: ' .. bullet2)
end
local kw = captures_at(8, 2)
if not has(kw, 'lua/keyword') then
  fail('fence body is not highlighted as lua: ' .. kw)
end

print 'claudeprompt highlight: OK'
vim.cmd 'qa!'
