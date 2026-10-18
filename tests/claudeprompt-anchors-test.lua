-- Plain-Lua tests for lua/claudeprompt-anchors.lua. Run from the repo root:
--   lua5.1 tests/claudeprompt-anchors-test.lua
-- (a local test/assert_eq harness; no busted, no vim.*)

local passed = 0
local failed = 0
local errors = {}

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print('  PASS: ' .. name)
  else
    failed = failed + 1
    errors[#errors + 1] = { name = name, err = err }
    print('  FAIL: ' .. name)
    print('        ' .. tostring(err))
  end
end

local function assert_eq(actual, expected, msg)
  if type(actual) == 'table' and type(expected) == 'table' then
    assert(#actual == #expected, (msg or '') .. ' length mismatch: ' .. #actual .. ' vs ' .. #expected)
    for i = 1, #actual do
      assert_eq(actual[i], expected[i], (msg or '') .. '[' .. i .. ']')
    end
  else
    assert(actual == expected, (msg or '') .. ' expected: ' .. tostring(expected) .. ', got: ' .. tostring(actual))
  end
end

package.path = 'lua/?.lua;lua/?/init.lua;' .. package.path
local anchors = require 'claudeprompt-anchors'

print '\n=== claudeprompt-anchors tests ===\n'

print '-- parse --'

test('single line: header after one code line', function()
  local a = anchors.parse 'foo()\n# lua/a.lua:12'
  assert_eq(a.path, 'lua/a.lua')
  assert_eq(a.range, '12')
  assert_eq(a.code, { 'foo()' })
end)

test('range: start-end survives as a string', function()
  local a = anchors.parse 'foo()\nbar()\n# lua/a.lua:12-20'
  assert_eq(a.range, '12-20')
  assert_eq(a.code, { 'foo()', 'bar()' })
end)

test('no header: returns nil', function()
  assert_eq(anchors.parse 'just some text\nno header here', nil)
end)

test('nil and empty input return nil', function()
  assert_eq(anchors.parse(nil), nil)
  assert_eq(anchors.parse '', nil)
end)

test('comment inside code: the last header wins, the earlier one stays code', function()
  local a = anchors.parse '# notes.py:3\nx = 1\n# src/real.py:40'
  assert_eq(a.path, 'src/real.py')
  assert_eq(a.range, '40')
  assert_eq(a.code, { '# notes.py:3', 'x = 1' })
end)

test('blank padding: leading blank line and trailing newline are trimmed from code', function()
  local a = anchors.parse '\nfoo()\n\n# lua/a.lua:1\n'
  assert_eq(a.code, { 'foo()' })
end)

test('CRLF clipboard: header parses and no \\r reaches the code', function()
  local a = anchors.parse 'foo()\r\n# lua/a.lua:12\r\n'
  assert_eq(a.path, 'lua/a.lua')
  assert_eq(a.code, { 'foo()' })
end)

test('colon in path: the final :digits is the range', function()
  local a = anchors.parse 'x\n# C:/work/a.lua:7'
  assert_eq(a.path, 'C:/work/a.lua')
  assert_eq(a.range, '7')
end)

test('header only: code is empty', function()
  local a = anchors.parse '# lua/a.lua:5'
  assert_eq(a.code, {})
end)

print '-- render --'

test('render with lang: path line, lua fence, code, closing fence', function()
  local lines = anchors.render({ path = 'lua/a.lua', range = '12-13', code = { 'local x', 'return x' } }, 'lua')
  assert_eq(lines, { 'lua/a.lua:12-13', '```lua', 'local x', 'return x', '```' })
end)

test('render without lang: bare fence', function()
  local lines = anchors.render({ path = 'a.txt', range = '1', code = { 'hi' } }, nil)
  assert_eq(lines, { 'a.txt:1', '```', 'hi', '```' })
end)

test('render picks a fence longer than any backtick run in the code', function()
  local lines = anchors.render({ path = 'n.md', range = '1-3', code = { '```lua', 'x', '```' } }, 'markdown')
  assert_eq(lines, { 'n.md:1-3', '````markdown', '```lua', 'x', '```', '````' })
end)

test('render with empty code: just the path line, no fence', function()
  assert_eq(anchors.render({ path = 'a.txt', range = '1', code = {} }, 'text'), { 'a.txt:1' })
end)

-- Summary
print('\n=== Results: ' .. passed .. ' passed, ' .. failed .. ' failed ===')
if failed > 0 then
  os.exit(1)
end
