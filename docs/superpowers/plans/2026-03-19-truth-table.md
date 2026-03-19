# Truth Table Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local Neovim plugin that generates, expands, and manipulates markdown truth tables inline.

**Architecture:** Single-file local plugin at `lua/custom/plugins/truth-table.lua` following the `rot13-comment.lua` pattern (self-contained Lua, returns `{}` for lazy.nvim). Contains a tokenizer, recursive descent parser, table detection/formatting utilities, and user commands with keymaps.

**Tech Stack:** Pure Lua, Neovim API (`vim.api`, `vim.keymap`, `vim.ui`)

---

## File Structure

- **Create:** `lua/custom/plugins/truth-table.lua` — user commands, keymaps, buffer operations (the "Neovim glue")
- **Create:** `lua/custom/plugins/truth-table-core.lua` — pure functions (formatter, tokenizer, parser, evaluator, heading generator, row generator, arg parser). Exported as a module via `return M`. No `vim.api` calls; only uses `vim.trim` and `vim.split` (available in headless Lua).
- **Create:** `tests/truth-table-test.lua` — test script run via `nvim --headless -l tests/truth-table-test.lua`

**Spec:** `docs/superpowers/specs/2026-03-19-truth-table-design.md`

**Testing approach:** All pure logic lives in `truth-table-core.lua` and is tested by `tests/truth-table-test.lua` using `nvim --headless -l`. The test script requires the core module, runs assertions, and prints results. Buffer-manipulating commands in `truth-table.lua` are verified manually.

---

### Task 1: Core Module — Formatting and Row Generation

The core module holds all pure functions. We start with formatting and row generation since everything else builds on them.

**Files:**
- Create: `lua/custom/plugins/truth-table-core.lua`

- [ ] **Step 1: Create the core module with formatting and row generation**

```lua
local M = {}

-- Center-pad a string to a given width
function M.center_pad(str, width)
  local pad = width - #str
  local left = math.floor(pad / 2)
  local right = pad - left
  return string.rep(' ', left) .. str .. string.rep(' ', right)
end

-- Build aligned markdown table lines from headers and rows
-- headers: list of strings
-- rows: list of lists of strings (each inner list same length as headers)
-- Returns: list of strings (heading, separator, data rows)
function M.format_table(headers, rows)
  -- Compute column widths (minimum 3 for `:---:` to work)
  local widths = {}
  for i, h in ipairs(headers) do
    widths[i] = math.max(3, #h)
  end
  for _, row in ipairs(rows) do
    for i, cell in ipairs(row) do
      widths[i] = math.max(widths[i], #cell)
    end
  end

  -- Build heading line
  local hdr_cells = {}
  for i, h in ipairs(headers) do
    hdr_cells[i] = ' ' .. M.center_pad(h, widths[i]) .. ' '
  end
  local heading = '|' .. table.concat(hdr_cells, '|') .. '|'

  -- Build separator line
  local sep_cells = {}
  for i = 1, #headers do
    sep_cells[i] = ':' .. string.rep('-', widths[i]) .. ':'
  end
  local separator = '|' .. table.concat(sep_cells, '|') .. '|'

  -- Build data rows
  local lines = { heading, separator }
  for _, row in ipairs(rows) do
    local cells = {}
    for i, cell in ipairs(row) do
      cells[i] = ' ' .. M.center_pad(cell, widths[i]) .. ' '
    end
    lines[#lines + 1] = '|' .. table.concat(cells, '|') .. '|'
  end

  return lines
end

-- Generate truth table rows for N variables
-- Returns list of rows, each row is a list of "0"/"1" strings
function M.generate_rows(n)
  local total = 2 ^ n
  local rows = {}
  for i = 0, total - 1 do
    local row = {}
    for col = 1, n do
      local bit = math.floor(i / (2 ^ (n - col))) % 2
      row[col] = tostring(bit)
    end
    rows[#rows + 1] = row
  end
  return rows
end

-- Parse :TruthTable arguments
-- Returns headers (list of strings) or nil + error message
function M.parse_truth_table_args(args)
  local input = vim.trim(args)
  if input == '' then
    return nil, 'Usage: :TruthTable N or :TruthTable name1 name2 ...'
  end

  local n = tonumber(input)
  if n then
    if n < 1 or n > 10 or n ~= math.floor(n) then
      return nil, 'N must be an integer between 1 and 10'
    end
    local headers = {}
    for i = 1, n do
      headers[i] = string.char(64 + i)
    end
    return headers
  end

  local headers = {}
  local seen = {}
  for name in input:gmatch('%S+') do
    if not name:match('^[A-Za-z_][A-Za-z0-9_]*$') then
      return nil, 'Invalid variable name: ' .. name
    end
    if seen[name] then
      return nil, 'Duplicate variable name: ' .. name
    end
    seen[name] = true
    headers[#headers + 1] = name
  end

  if #headers > 10 then
    return nil, 'Too many variables (max 10)'
  end

  return headers
end

return M
```

- [ ] **Step 2: Commit**

```bash
git add lua/custom/plugins/truth-table-core.lua
git commit -m "feat(truth-table): add core module with formatting and row generation"
```

---

### Task 2: Tests for Formatting and Row Generation

Write tests for Task 1's pure functions before moving on.

**Files:**
- Create: `tests/truth-table-test.lua`

- [ ] **Step 1: Write the test harness and formatting/generation tests**

```lua
-- Minimal test runner for nvim --headless -l
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

-- Add the plugin directory to the Lua path so require works
package.path = 'lua/?.lua;lua/?/init.lua;' .. package.path
local core = require('custom.plugins.truth-table-core')

print('\n=== Truth Table Core Tests ===\n')

-- format_table tests
print('-- format_table --')

test('format_table with 2 columns', function()
  local lines = core.format_table({ 'A', 'B' }, { { '0', '0' }, { '0', '1' }, { '1', '0' }, { '1', '1' } })
  assert_eq(lines[1], '|  A  |  B  |')
  assert_eq(lines[2], '|:---:|:---:|')
  assert_eq(lines[3], '|  0  |  0  |')
  assert_eq(#lines, 6) -- header + sep + 4 rows
end)

test('format_table pads to longest header', function()
  local lines = core.format_table({ 'error', 'timeout' }, { { '0', '0' } })
  assert(lines[1]:find('error'), 'should contain error')
  assert(lines[1]:find('timeout'), 'should contain timeout')
  -- Separator dashes should be at least as wide as header
  assert(lines[2]:find(':%-%-%-%-%-:'), 'separator should have >= 5 dashes for error')
end)

-- generate_rows tests
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
  assert_eq(rows[2], { '0', '0', '1' }) -- only LSB flips
end)

-- parse_truth_table_args tests
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
```

- [ ] **Step 2: Run the tests**

Run: `nvim --headless -l tests/truth-table-test.lua`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add tests/truth-table-test.lua
git commit -m "test(truth-table): add tests for formatting and row generation"
```

---

### Task 3: `:TruthTable` Command (Thin Wrapper)

The command itself just calls core functions and writes to the buffer.

**Files:**
- Create: `lua/custom/plugins/truth-table.lua`

- [ ] **Step 1: Write the `TruthTable` command**

```lua
local core = require('custom.plugins.truth-table-core')

vim.api.nvim_create_user_command('TruthTable', function(opts)
  local headers, err = core.parse_truth_table_args(opts.args)
  if not headers then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local rows = core.generate_rows(#headers)
  local lines = core.format_table(headers, rows)

  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1] - 1, false, lines)
end, { nargs = '+', desc = 'Generate a truth table' })
```

- [ ] **Step 2: Test manually**

Open a blank buffer, run `:TruthTable 3` and `:TruthTable error timeout`. Verify output matches spec.

- [ ] **Step 3: Commit**

```bash
git add lua/custom/plugins/truth-table.lua
git commit -m "feat(truth-table): add :TruthTable command"
```

---

### Task 4: Core Module — Table Detection Helpers

The pure helper functions (`is_table_line`, `is_separator`, `split_row`, `parse_table_lines`) go in the core module. The buffer-scanning `find_table` function stays in `truth-table.lua` since it uses `vim.api`.

**Files:**
- Modify: `lua/custom/plugins/truth-table-core.lua`

- [ ] **Step 1: Add table detection helpers to the core module**

Append to `truth-table-core.lua` before `return M`:

```lua
-- Check if a line looks like a table row: starts and ends with |
function M.is_table_line(line)
  return line:match('^%s*|.*|%s*$') ~= nil
end

-- Check if a line is a separator row (e.g., |:---:|:---:|)
function M.is_separator(line)
  local inner = line:match('^%s*|(.+)|%s*$')
  if not inner then return false end
  for cell in (inner .. '|'):gmatch('(.-)%|') do
    if not cell:match('^%s*:?%-+:?%s*$') then
      return false
    end
  end
  return true
end

-- Split a table row into cell contents (trimmed)
function M.split_row(line)
  local cells = {}
  local inner = line:match('^%s*|(.+)|%s*$')
  if not inner then return cells end
  for cell in (inner .. '|'):gmatch('(.-)%|') do
    cells[#cells + 1] = vim.trim(cell)
  end
  return cells
end

-- Parse a list of table lines (strings) into structured data
-- lines[1] = heading, lines[2] = separator, lines[3+] = data rows
-- Returns { headers = {...}, rows = {{...}, ...} }
function M.parse_table_lines(lines)
  local headers = M.split_row(lines[1])
  local rows = {}
  for i = 3, #lines do
    rows[#rows + 1] = M.split_row(lines[i])
  end
  return { headers = headers, rows = rows }
end
```

- [ ] **Step 2: Add `find_table` and `parse_table` to `truth-table.lua`**

These are the buffer-aware wrappers that live in the plugin file:

```lua
-- Find the table surrounding the cursor
-- Returns start_line, end_line (1-indexed) or nil
local function find_table()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cur_row = cursor[1]
  local total = vim.api.nvim_buf_line_count(0)

  local cur_line = vim.api.nvim_buf_get_lines(0, cur_row - 1, cur_row, false)[1]
  if not core.is_table_line(cur_line) then
    return nil
  end

  local start_row = cur_row
  for row = cur_row - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if not core.is_table_line(line) then break end
    start_row = row
  end

  local end_row = cur_row
  for row = cur_row + 1, total do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if not core.is_table_line(line) then break end
    end_row = row
  end

  if end_row - start_row < 1 then return nil end

  local sep_line = vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1]
  if not core.is_separator(sep_line) then return nil end

  return start_row, end_row
end

local function parse_table(start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local tbl = core.parse_table_lines(lines)
  tbl.start_line = start_line
  tbl.end_line = end_line
  return tbl
end
```

- [ ] **Step 3: Add tests for table detection helpers**

Append to `tests/truth-table-test.lua`:

```lua
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
```

- [ ] **Step 4: Run tests**

Run: `nvim --headless -l tests/truth-table-test.lua`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lua/custom/plugins/truth-table-core.lua lua/custom/plugins/truth-table.lua tests/truth-table-test.lua
git commit -m "feat(truth-table): add table detection helpers with tests"
```

---

### Task 5: Core Module — Predicate Parser (Tokenizer + AST)

Implements the tokenizer, recursive descent parser, evaluator, and heading generator. All pure functions in the core module.

**Files:**
- Modify: `lua/custom/plugins/truth-table-core.lua`

- [ ] **Step 1: Add the tokenizer to the core module**

Append to `truth-table-core.lua` before `return M`:

```lua
-- Tokenize a predicate string
-- Returns list of tokens: { type = "ident"|"op"|"paren"|"literal", value = string }
function M.tokenize(input)
  local tokens = {}
  local pos = 1
  local len = #input

  while pos <= len do
    -- Skip whitespace
    local ws = input:match('^%s+', pos)
    if ws then
      pos = pos + #ws
    end
    if pos > len then break end

    local ch = input:sub(pos, pos)

    if ch == '(' or ch == ')' then
      tokens[#tokens + 1] = { type = 'paren', value = ch }
      pos = pos + 1
    elseif ch == '!' then
      tokens[#tokens + 1] = { type = 'op', value = '!' }
      pos = pos + 1
    elseif ch:match('[A-Za-z_]') then
      local ident = input:match('^[A-Za-z_][A-Za-z0-9_]*', pos)
      -- Check if it's a keyword
      if ident == 'and' or ident == 'or' or ident == 'xor' or ident == 'not' then
        tokens[#tokens + 1] = { type = 'op', value = ident }
      else
        tokens[#tokens + 1] = { type = 'ident', value = ident }
      end
      pos = pos + #ident
    elseif ch == '0' or ch == '1' then
      tokens[#tokens + 1] = { type = 'literal', value = ch }
      pos = pos + 1
    else
      return nil, 'Unexpected character: ' .. ch .. ' at position ' .. pos
    end
  end

  return tokens
end
```

- [ ] **Step 2: Add the recursive descent parser**

```lua
-- Recursive descent parser
-- Returns AST node or nil + error message
function M.parse_predicate(tokens)
  local pos = 1

  local function peek()
    return tokens[pos]
  end

  local function consume()
    local tok = tokens[pos]
    pos = pos + 1
    return tok
  end

  local function expect(type, value)
    local tok = peek()
    if not tok or tok.type ~= type or (value and tok.value ~= value) then
      return nil, 'Expected ' .. (value or type) .. ' at token ' .. pos
    end
    return consume()
  end

  -- Forward declaration
  local parse_expr

  local function parse_atom()
    local tok = peek()
    if not tok then
      return nil, 'Unexpected end of expression'
    end

    if tok.type == 'ident' then
      consume()
      return { type = 'var', name = tok.value }
    elseif tok.type == 'literal' then
      consume()
      return { type = 'literal', value = tonumber(tok.value) }
    elseif tok.type == 'paren' and tok.value == '(' then
      consume()
      local node, err = parse_expr()
      if not node then return nil, err end
      local _, err2 = expect('paren', ')')
      if not _ then return nil, err2 or 'Expected closing parenthesis' end
      return node
    else
      return nil, 'Unexpected token: ' .. tok.value
    end
  end

  local function parse_unary()
    local tok = peek()
    if tok and tok.type == 'op' and (tok.value == 'not' or tok.value == '!') then
      consume()
      local operand, err = parse_unary()
      if not operand then return nil, err end
      return { type = 'not', operand = operand }
    end
    return parse_atom()
  end

  local function parse_and()
    local left, err = parse_unary()
    if not left then return nil, err end
    while peek() and peek().type == 'op' and peek().value == 'and' do
      consume()
      local right, err2 = parse_unary()
      if not right then return nil, err2 end
      left = { type = 'and', left = left, right = right }
    end
    return left
  end

  local function parse_or()
    local left, err = parse_and()
    if not left then return nil, err end
    while peek() and peek().type == 'op' and peek().value == 'or' do
      consume()
      local right, err2 = parse_and()
      if not right then return nil, err2 end
      left = { type = 'or', left = left, right = right }
    end
    return left
  end

  local function parse_xor()
    local left, err = parse_or()
    if not left then return nil, err end
    while peek() and peek().type == 'op' and peek().value == 'xor' do
      consume()
      local right, err2 = parse_or()
      if not right then return nil, err2 end
      left = { type = 'xor', left = left, right = right }
    end
    return left
  end

  parse_expr = parse_xor

  local result, err = parse_expr()
  if not result then return nil, err end

  -- Check for leftover tokens
  if pos <= #tokens then
    return nil, 'Unexpected token after expression: ' .. tokens[pos].value
  end

  return result
end
```

- [ ] **Step 3: Add AST evaluation and heading generation**

```lua
-- Symbol mapping for heading display
M.SYMBOLS = {
  ['and'] = '∧',
  ['or'] = '∨',
  ['xor'] = '⊕',
  ['not'] = '¬',
  ['!'] = '¬',
}

-- Evaluate an AST node given a row context (map of name -> 0/1)
function M.eval_ast(node, ctx)
  if node.type == 'var' then
    return ctx[node.name]
  elseif node.type == 'literal' then
    return node.value
  elseif node.type == 'not' then
    return M.eval_ast(node.operand, ctx) == 0 and 1 or 0
  elseif node.type == 'and' then
    return (M.eval_ast(node.left, ctx) == 1 and M.eval_ast(node.right, ctx) == 1) and 1 or 0
  elseif node.type == 'or' then
    return (M.eval_ast(node.left, ctx) == 1 or M.eval_ast(node.right, ctx) == 1) and 1 or 0
  elseif node.type == 'xor' then
    return M.eval_ast(node.left, ctx) ~= M.eval_ast(node.right, ctx) and 1 or 0
  end
end

-- Generate heading string from AST (operators replaced with symbols)
function M.ast_to_heading(node)
  if node.type == 'var' then
    return node.name
  elseif node.type == 'literal' then
    return tostring(node.value)
  elseif node.type == 'not' then
    return M.SYMBOLS['not'] .. M.ast_to_heading(node.operand)
  elseif node.type == 'and' or node.type == 'or' or node.type == 'xor' then
    return M.ast_to_heading(node.left) .. ' ' .. M.SYMBOLS[node.type] .. ' ' .. M.ast_to_heading(node.right)
  end
end
```

- [ ] **Step 4: Add parser and evaluator tests**

Append to `tests/truth-table-test.lua`:

```lua
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
  assert_eq(ast.left.type, 'or')
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
```

- [ ] **Step 5: Run tests**

Run: `nvim --headless -l tests/truth-table-test.lua`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lua/custom/plugins/truth-table-core.lua tests/truth-table-test.lua
git commit -m "feat(truth-table): add predicate parser, evaluator, and heading generator with tests"
```

---

### Task 6: `:TruthTableExpand` Command

Implements the command to append computed columns to an existing table.

**Files:**
- Modify: `lua/custom/plugins/truth-table.lua`

- [ ] **Step 1: Write the `TruthTableExpand` command**

```lua
-- Validate that all variable references in an AST exist in the header list
local function validate_vars(node, header_set)
  if node.type == 'var' then
    if not header_set[node.name] then
      return 'Unknown column: ' .. node.name
    end
  elseif node.type == 'not' then
    return validate_vars(node.operand, header_set)
  elseif node.type == 'and' or node.type == 'or' or node.type == 'xor' then
    local err = validate_vars(node.left, header_set)
    if err then return err end
    return validate_vars(node.right, header_set)
  end
  return nil
end

vim.api.nvim_create_user_command('TruthTableExpand', function(opts)
  local start_line, end_line = find_table()
  if not start_line then
    vim.notify('Cursor is not inside a truth table', vim.log.levels.WARN)
    return
  end

  local tbl = parse_table(start_line, end_line)
  local header_set = {}
  for _, h in ipairs(tbl.headers) do
    header_set[h] = true
  end

  local predicates = vim.split(opts.args, ',', { trimempty = true })
  if #predicates == 0 then
    vim.notify('Usage: :TruthTableExpand predicate1, predicate2, ...', vim.log.levels.WARN)
    return
  end

  local parsed = {}
  for _, pred_str in ipairs(predicates) do
    pred_str = vim.trim(pred_str)
    local tokens, tok_err = core.tokenize(pred_str)
    if not tokens then
      vim.notify('Parse error: ' .. tok_err, vim.log.levels.ERROR)
      return
    end
    local ast, parse_err = core.parse_predicate(tokens)
    if not ast then
      vim.notify('Parse error in "' .. pred_str .. '": ' .. parse_err, vim.log.levels.ERROR)
      return
    end
    local var_err = validate_vars(ast, header_set)
    if var_err then
      vim.notify(var_err, vim.log.levels.ERROR)
      return
    end
    parsed[#parsed + 1] = { ast = ast, heading = core.ast_to_heading(ast) }
  end

  local new_headers = vim.list_extend({}, tbl.headers)
  for _, p in ipairs(parsed) do
    new_headers[#new_headers + 1] = p.heading
  end

  local new_rows = {}
  for _, row in ipairs(tbl.rows) do
    local ctx = {}
    for i, h in ipairs(tbl.headers) do
      ctx[h] = tonumber(row[i])
    end
    local new_row = vim.list_extend({}, row)
    for _, p in ipairs(parsed) do
      new_row[#new_row + 1] = tostring(core.eval_ast(p.ast, ctx))
    end
    new_rows[#new_rows + 1] = new_row
  end

  local lines = core.format_table(new_headers, new_rows)
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
end, { nargs = '+', desc = 'Expand truth table with computed columns' })
```

- [ ] **Step 2: Test manually**

1. Generate a table: `:TruthTable error timeout`
2. Place cursor inside the table
3. Run: `:TruthTableExpand error and timeout, error or timeout`
4. Verify two new columns appear with headings `error ∧ timeout` and `error ∨ timeout`
5. Test: `:TruthTableExpand !error and timeout` — heading should be `¬error ∧ timeout`
6. Test error case: `:TruthTableExpand foo and bar` — should warn about unknown column

- [ ] **Step 3: Commit**

```bash
git add lua/custom/plugins/truth-table.lua
git commit -m "feat(truth-table): add :TruthTableExpand command"
```

---

### Task 7: `:TruthTableDropRow` Command

**Files:**
- Modify: `lua/custom/plugins/truth-table.lua`

- [ ] **Step 1: Write the `TruthTableDropRow` command**

```lua
vim.api.nvim_create_user_command('TruthTableDropRow', function()
  local start_line, end_line = find_table()
  if not start_line then
    vim.notify('Cursor is not inside a truth table', vim.log.levels.WARN)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cur_row = cursor[1]

  -- Heading is start_line, separator is start_line + 1
  if cur_row <= start_line + 1 then
    vim.notify('Cannot drop heading or separator row', vim.log.levels.WARN)
    return
  end

  -- Remove the row and reformat as a single undo step
  local tbl = parse_table(start_line, end_line)
  local row_idx = cur_row - start_line - 1 -- offset past heading and separator
  table.remove(tbl.rows, row_idx)

  local lines = core.format_table(tbl.headers, tbl.rows)
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
end, { desc = 'Drop the current truth table row' })
```

- [ ] **Step 2: Test manually**

1. Generate: `:TruthTable 2`
2. Place cursor on a data row, run `:TruthTableDropRow` — row should be removed
3. Place cursor on heading row, run `:TruthTableDropRow` — should warn
4. Place cursor on separator row, run `:TruthTableDropRow` — should warn

- [ ] **Step 3: Commit**

```bash
git add lua/custom/plugins/truth-table.lua
git commit -m "feat(truth-table): add :TruthTableDropRow command"
```

---

### Task 8: `:TruthTableDropColumn` Command

**Files:**
- Modify: `lua/custom/plugins/truth-table.lua`

- [ ] **Step 1: Write column index detection and the command**

```lua
-- Determine which column the cursor is in (1-indexed) by counting | delimiters
local function get_cursor_column_index()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local col = cursor[2] -- 0-indexed byte offset
  local line = vim.api.nvim_get_current_line()
  local count = 0
  for i = 1, col + 1 do
    if line:sub(i, i) == '|' then
      count = count + 1
    end
  end
  -- The cursor is in column `count` (after the count-th pipe)
  -- If count is 0, cursor is before the first pipe
  return math.max(1, count)
end

vim.api.nvim_create_user_command('TruthTableDropColumn', function()
  local start_line, end_line = find_table()
  if not start_line then
    vim.notify('Cursor is not inside a truth table', vim.log.levels.WARN)
    return
  end

  local tbl = parse_table(start_line, end_line)

  if #tbl.headers <= 1 then
    vim.notify('Cannot drop the only column', vim.log.levels.WARN)
    return
  end

  local col_idx = get_cursor_column_index()
  if col_idx > #tbl.headers then
    col_idx = #tbl.headers
  end

  -- Remove the column from headers and all rows
  table.remove(tbl.headers, col_idx)
  for _, row in ipairs(tbl.rows) do
    table.remove(row, col_idx)
  end

  -- Rewrite the table
  local lines = core.format_table(tbl.headers, tbl.rows)
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
end, { desc = 'Drop the current truth table column' })
```

- [ ] **Step 2: Test manually**

1. Generate: `:TruthTable A B C`
2. Place cursor in column B, run `:TruthTableDropColumn` — column B should be removed
3. Drop again until one column remains — should warn "Cannot drop the only column"

- [ ] **Step 3: Commit**

```bash
git add lua/custom/plugins/truth-table.lua
git commit -m "feat(truth-table): add :TruthTableDropColumn command"
```

---

### Task 9: Keymaps and Which-Key Group

**Files:**
- Modify: `lua/custom/plugins/truth-table.lua`

- [ ] **Step 1: Add keymaps and return statement**

```lua
-- Which-key group registration (if which-key is available)
local ok, wk = pcall(require, 'which-key')
if ok then
  wk.add {
    { '<leader>tt', group = '[T]ruth Table' },
  }
end

-- Keymaps
vim.keymap.set('n', '<leader>ttn', function()
  vim.ui.input({ prompt = 'TruthTable args (N or name1 name2 ...): ' }, function(input)
    if input and input ~= '' then
      vim.cmd('TruthTable ' .. input)
    end
  end)
end, { desc = 'New truth table' })

vim.keymap.set('n', '<leader>tte', function()
  vim.ui.input({ prompt = 'TruthTableExpand predicates: ' }, function(input)
    if input and input ~= '' then
      vim.cmd('TruthTableExpand ' .. input)
    end
  end)
end, { desc = 'Expand truth table' })

vim.keymap.set('n', '<leader>ttr', '<cmd>TruthTableDropRow<CR>', { desc = 'Drop truth table row' })
vim.keymap.set('n', '<leader>ttc', '<cmd>TruthTableDropColumn<CR>', { desc = 'Drop truth table column' })

return {}
```

- [ ] **Step 2: Test keymaps**

1. Restart Neovim (so lazy.nvim loads the plugin)
2. Press `<leader>tt` — which-key popup should show `[T]ruth Table` group
3. Press `<leader>ttn`, enter `3` — table should appear
4. Press `<leader>tte`, enter `A and B` — column should be added
5. Press `<leader>ttr` on a data row — row should be removed
6. Press `<leader>ttc` on a column — column should be removed

- [ ] **Step 3: Commit**

```bash
git add lua/custom/plugins/truth-table.lua
git commit -m "feat(truth-table): add keymaps and which-key group"
```
