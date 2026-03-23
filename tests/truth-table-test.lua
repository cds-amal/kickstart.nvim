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
local core = require('custom.truth-table-core')

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

-- is_table_line tests
print('\n-- is_table_line --')

test('recognizes table line', function()
  assert(core.is_table_line('| A | B |') == true)
end)

test('rejects non-table line', function()
  assert(core.is_table_line('hello world') == false)
end)

test('rejects single pipe', function()
  assert(core.is_table_line('| only one side') == false)
end)

-- is_separator tests
print('\n-- is_separator --')

test('recognizes centered separator', function()
  assert(core.is_separator('|:---:|:---:|') == true)
end)

test('recognizes left-aligned separator', function()
  assert(core.is_separator('|:---|:---|') == true)
end)

test('recognizes plain separator', function()
  assert(core.is_separator('|---|---|') == true)
end)

test('rejects non-separator table line', function()
  assert(core.is_separator('| A | B |') == false)
end)

test('rejects separator without dashes', function()
  assert(core.is_separator('|::|::|') == false)
end)

-- split_row tests
print('\n-- split_row --')

test('splits simple row', function()
  local cells = core.split_row('| A | B | C |')
  assert_eq(cells, { 'A', 'B', 'C' })
end)

test('splits padded row', function()
  local cells = core.split_row('|   0   |   1   |')
  assert_eq(cells, { '0', '1' })
end)

-- parse_table_lines tests
print('\n-- parse_table_lines --')

test('parses table lines', function()
  local lines = {
    '| A | B |',
    '|:---:|:---:|',
    '| 0 | 0 |',
    '| 0 | 1 |',
  }
  local tbl = core.parse_table_lines(lines)
  assert_eq(tbl.headers, { 'A', 'B' })
  assert_eq(#tbl.rows, 2)
  assert_eq(tbl.rows[1], { '0', '0' })
  assert_eq(tbl.rows[2], { '0', '1' })
end)

-- tokenizer tests
print('\n-- tokenize --')

test('tokenizes simple expression', function()
  local tokens = core.tokenize('A and B')
  assert_eq(#tokens, 3)
  assert_eq(tokens[1].type, 'ident')
  assert_eq(tokens[1].value, 'A')
  assert_eq(tokens[2].type, 'op')
  assert_eq(tokens[2].value, 'and')
  assert_eq(tokens[3].type, 'ident')
  assert_eq(tokens[3].value, 'B')
end)

test('tokenizes ! without space', function()
  local tokens = core.tokenize('!A')
  assert_eq(#tokens, 2)
  assert_eq(tokens[1].type, 'op')
  assert_eq(tokens[1].value, '!')
  assert_eq(tokens[2].type, 'ident')
  assert_eq(tokens[2].value, 'A')
end)

test('tokenizes parentheses', function()
  local tokens = core.tokenize('(A or B) and C')
  assert_eq(#tokens, 7)
  assert_eq(tokens[1].value, '(')
  assert_eq(tokens[5].value, ')')
end)

test('tokenizes literals', function()
  local tokens = core.tokenize('A and 1')
  assert_eq(tokens[3].type, 'literal')
  assert_eq(tokens[3].value, '1')
end)

test('rejects invalid character', function()
  local tokens, err = core.tokenize('A & B')
  assert(tokens == nil)
  assert(err:find('Unexpected character'))
end)

-- parser tests
print('\n-- parse_predicate --')

test('parses simple and', function()
  local tokens = core.tokenize('A and B')
  local ast = core.parse_predicate(tokens)
  assert_eq(ast.type, 'and')
  assert_eq(ast.left.type, 'var')
  assert_eq(ast.left.name, 'A')
  assert_eq(ast.right.name, 'B')
end)

test('parses not', function()
  local tokens = core.tokenize('not A')
  local ast = core.parse_predicate(tokens)
  assert_eq(ast.type, 'not')
  assert_eq(ast.operand.name, 'A')
end)

test('parses ! shorthand', function()
  local tokens = core.tokenize('!A')
  local ast = core.parse_predicate(tokens)
  assert_eq(ast.type, 'not')
  assert_eq(ast.operand.name, 'A')
end)

test('precedence: and binds tighter than or', function()
  local tokens = core.tokenize('A or B and C')
  local ast = core.parse_predicate(tokens)
  assert_eq(ast.type, 'or')
  assert_eq(ast.right.type, 'and')
end)

test('parentheses override precedence', function()
  local tokens = core.tokenize('(A or B) and C')
  local ast = core.parse_predicate(tokens)
  assert_eq(ast.type, 'and')
  assert_eq(ast.left.type, 'paren')
  assert_eq(ast.left.expr.type, 'or')
end)

-- eval_ast tests
print('\n-- eval_ast --')

test('eval and', function()
  local tokens = core.tokenize('A and B')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.eval_ast(ast, { A = 1, B = 1 }), 1)
  assert_eq(core.eval_ast(ast, { A = 1, B = 0 }), 0)
  assert_eq(core.eval_ast(ast, { A = 0, B = 0 }), 0)
end)

test('eval or', function()
  local tokens = core.tokenize('A or B')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.eval_ast(ast, { A = 0, B = 0 }), 0)
  assert_eq(core.eval_ast(ast, { A = 1, B = 0 }), 1)
end)

test('eval xor', function()
  local tokens = core.tokenize('A xor B')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.eval_ast(ast, { A = 1, B = 1 }), 0)
  assert_eq(core.eval_ast(ast, { A = 1, B = 0 }), 1)
end)

test('eval not', function()
  local tokens = core.tokenize('not A')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.eval_ast(ast, { A = 1 }), 0)
  assert_eq(core.eval_ast(ast, { A = 0 }), 1)
end)

test('eval complex: !A and B', function()
  local tokens = core.tokenize('!A and B')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.eval_ast(ast, { A = 0, B = 1 }), 1)
  assert_eq(core.eval_ast(ast, { A = 1, B = 1 }), 0)
end)

-- ast_to_heading tests
print('\n-- ast_to_heading --')

test('heading for A and B', function()
  local tokens = core.tokenize('A and B')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.ast_to_heading(ast), 'A ∧ B')
end)

test('heading for not A', function()
  local tokens = core.tokenize('not A')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.ast_to_heading(ast), '¬A')
end)

test('heading for !A', function()
  local tokens = core.tokenize('!A')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.ast_to_heading(ast), '¬A')
end)

test('heading for A xor B', function()
  local tokens = core.tokenize('A xor B')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.ast_to_heading(ast), 'A ⊕ B')
end)

test('heading for A or B', function()
  local tokens = core.tokenize('A or B')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.ast_to_heading(ast), 'A ∨ B')
end)

test('heading preserves user parentheses', function()
  local tokens = core.tokenize('!(!T or !E or S)')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.ast_to_heading(ast), '¬(¬T ∨ ¬E ∨ S)')
end)

test('eval with parenthesized subexpression', function()
  local tokens = core.tokenize('!(A or B)')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.eval_ast(ast, { A = 0, B = 0 }), 1)
  assert_eq(core.eval_ast(ast, { A = 1, B = 0 }), 0)
  assert_eq(core.eval_ast(ast, { A = 0, B = 1 }), 0)
end)

-- implies tests
print('\n-- implies --')

test('tokenizes implies keyword', function()
  local tokens = core.tokenize('A implies B')
  assert_eq(#tokens, 3)
  assert_eq(tokens[2].type, 'op')
  assert_eq(tokens[2].value, 'implies')
end)

test('tokenizes -> as implies', function()
  local tokens = core.tokenize('A -> B')
  assert_eq(#tokens, 3)
  assert_eq(tokens[2].value, 'implies')
end)

test('eval implies: 0->0=1, 0->1=1, 1->0=0, 1->1=1', function()
  local tokens = core.tokenize('A implies B')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.eval_ast(ast, { A = 0, B = 0 }), 1)
  assert_eq(core.eval_ast(ast, { A = 0, B = 1 }), 1)
  assert_eq(core.eval_ast(ast, { A = 1, B = 0 }), 0)
  assert_eq(core.eval_ast(ast, { A = 1, B = 1 }), 1)
end)

test('heading for A implies B', function()
  local tokens = core.tokenize('A implies B')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.ast_to_heading(ast), 'A → B')
end)

test('heading for A -> B', function()
  local tokens = core.tokenize('A -> B')
  local ast = core.parse_predicate(tokens)
  assert_eq(core.ast_to_heading(ast), 'A → B')
end)

test('implies binds looser than xor', function()
  local tokens = core.tokenize('A xor B implies C')
  local ast = core.parse_predicate(tokens)
  assert_eq(ast.type, 'implies')
  assert_eq(ast.left.type, 'xor')
end)

-- Unicode display width tests
print('\n-- unicode display width --')

test('format_table aligns correctly with unicode symbols', function()
  local lines = core.format_table({ 'A', 'B', 'A ∧ B' }, { { '0', '0', '0' } })
  -- The separator dashes for 'A ∧ B' (5 display chars) should be 5 dashes, not 7
  -- Each column should have consistent visual width
  local sep_cells = {}
  local inner = lines[2]:match('^|(.+)|$')
  for cell in (inner .. '|'):gmatch('(.-)%|') do
    sep_cells[#sep_cells + 1] = cell
  end
  -- Third column separator should match display width of 'A ∧ B' (5 chars)
  local dashes = sep_cells[3]:match('%-+')
  assert(#dashes >= 5, 'should have at least 5 dashes, got ' .. #dashes)
end)

-- Summary
print('\n=== Results: ' .. passed .. ' passed, ' .. failed .. ' failed ===')
if failed > 0 then
  os.exit(1)
end
