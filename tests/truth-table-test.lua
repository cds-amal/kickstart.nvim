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
local core = require('custom.plugins.truth-table-core')

print('\n=== Truth Table Core Tests ===\n')

print('-- format_table --')

test('format_table with 2 columns', function()
  local lines = core.format_table({ 'A', 'B' }, { { '0', '0' }, { '0', '1' }, { '1', '0' }, { '1', '1' } })
  assert_eq(lines[1], '|  A  |  B  |')
  assert_eq(lines[2], '|:---:|:---:|')
  assert_eq(lines[3], '|  0  |  0  |')
  assert_eq(#lines, 6)
end)

test('format_table pads to longest header', function()
  local lines = core.format_table({ 'error', 'timeout' }, { { '0', '0' } })
  assert(lines[1]:find('error'), 'should contain error')
  assert(lines[1]:find('timeout'), 'should contain timeout')
  assert(lines[2]:find(':%-%-%-%-%-:'), 'separator should have >= 5 dashes for error')
end)

print('\n-- generate_rows --')

test('generate_rows 1 variable', function()
  local rows = core.generate_rows(1)
  assert_eq(#rows, 2)
  assert_eq(rows[1], { '0' })
  assert_eq(rows[2], { '1' })
end)

test('generate_rows 2 variables', function()
  local rows = core.generate_rows(2)
  assert_eq(#rows, 4)
  assert_eq(rows[1], { '0', '0' })
  assert_eq(rows[2], { '0', '1' })
  assert_eq(rows[3], { '1', '0' })
  assert_eq(rows[4], { '1', '1' })
end)

test('generate_rows 3 variables LSB is rightmost', function()
  local rows = core.generate_rows(3)
  assert_eq(#rows, 8)
  assert_eq(rows[1], { '0', '0', '0' })
  assert_eq(rows[8], { '1', '1', '1' })
  assert_eq(rows[2], { '0', '0', '1' })
end)

print('\n-- parse_truth_table_args --')

test('parse numeric arg', function()
  local headers = core.parse_truth_table_args('3')
  assert_eq(headers, { 'A', 'B', 'C' })
end)

test('parse named args', function()
  local headers = core.parse_truth_table_args('error timeout')
  assert_eq(headers, { 'error', 'timeout' })
end)

test('reject N=0', function()
  local headers, err = core.parse_truth_table_args('0')
  assert(headers == nil)
  assert(err:find('integer between 1 and 10'))
end)

test('reject N=11', function()
  local headers, err = core.parse_truth_table_args('11')
  assert(headers == nil)
end)

test('reject duplicate names', function()
  local headers, err = core.parse_truth_table_args('error error')
  assert(headers == nil)
  assert(err:find('Duplicate'))
end)

test('reject invalid name', function()
  local headers, err = core.parse_truth_table_args('123abc')
  assert(headers == nil)
  assert(err:find('Invalid'))
end)

-- Summary
print('\n=== Results: ' .. passed .. ' passed, ' .. failed .. ' failed ===')
if failed > 0 then
  os.exit(1)
end
