# Truth Table Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local Neovim plugin that generates, expands, and manipulates markdown truth tables inline.

**Architecture:** Single-file local plugin at `lua/custom/plugins/truth-table.lua` following the `rot13-comment.lua` pattern (self-contained Lua, returns `{}` for lazy.nvim). Contains a tokenizer, recursive descent parser, table detection/formatting utilities, and user commands with keymaps.

**Tech Stack:** Pure Lua, Neovim API (`vim.api`, `vim.keymap`, `vim.ui`)

---

## File Structure

- **Create:** `lua/custom/plugins/truth-table.lua` — all plugin logic (table generation, parser, formatting, commands, keymaps)

**Spec:** `docs/superpowers/specs/2026-03-19-truth-table-design.md`

---

### Task 1: Table Formatting Utilities

The formatting functions are used by every other task, so they come first. These produce aligned markdown table strings from column headers and row data.

**Files:**
- Create: `lua/custom/plugins/truth-table.lua`

- [ ] **Step 1: Write `center_pad` and `format_table` functions**

`center_pad(str, width)` pads a string to `width` with spaces, centering it. `format_table(headers, rows)` takes a list of header strings and a list of rows (each row is a list of strings), returns a list of formatted markdown lines.

```lua
-- Center-pad a string to a given width
local function center_pad(str, width)
  local pad = width - #str
  local left = math.floor(pad / 2)
  local right = pad - left
  return string.rep(' ', left) .. str .. string.rep(' ', right)
end

-- Build aligned markdown table lines from headers and rows
-- headers: list of strings
-- rows: list of lists of strings (each inner list same length as headers)
-- Returns: list of strings (heading, separator, data rows)
local function format_table(headers, rows)
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
    hdr_cells[i] = ' ' .. center_pad(h, widths[i]) .. ' '
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
      cells[i] = ' ' .. center_pad(cell, widths[i]) .. ' '
    end
    lines[#lines + 1] = '|' .. table.concat(cells, '|') .. '|'
  end

  return lines
end
```

- [ ] **Step 2: Verify formatting manually**

Open Neovim, source the file with `:luafile lua/custom/plugins/truth-table.lua`, and run in command mode:

```
:lua print(table.concat(require('truth-table-test')({'A','B'},{{'0','0'},{'0','1'},{'1','0'},{'1','1'}}), '\n'))
```

(We will not have an exportable test harness; manual verification is fine for a config plugin. The function is internal so we verify by visual inspection after Task 2 generates a real table.)

- [ ] **Step 3: Commit**

```bash
git add lua/custom/plugins/truth-table.lua
git commit -m "feat(truth-table): add table formatting utilities"
```

---

### Task 2: `:TruthTable` Command (Table Generation)

Implements the `:TruthTable {args}` command that generates a truth table at the cursor position.

**Files:**
- Modify: `lua/custom/plugins/truth-table.lua`

- [ ] **Step 1: Write argument parsing and row generation**

```lua
-- Generate truth table rows for N variables
-- Returns list of rows, each row is a list of "0"/"1" strings
local function generate_rows(n)
  local total = 2 ^ n
  local rows = {}
  for i = 0, total - 1 do
    local row = {}
    for col = 1, n do
      -- Leftmost column is MSB: bit weight 2^(n-1), 2^(n-2), ..., 2^0
      local bit = math.floor(i / (2 ^ (n - col))) % 2
      row[col] = tostring(bit)
    end
    rows[#rows + 1] = row
  end
  return rows
end

-- Parse :TruthTable arguments
-- Returns headers (list of strings) or nil + error message
local function parse_truth_table_args(args)
  local input = vim.trim(args)
  if input == '' then
    return nil, 'Usage: :TruthTable N or :TruthTable name1 name2 ...'
  end

  -- Check if input is a single number
  local n = tonumber(input)
  if n then
    if n < 1 or n > 10 or n ~= math.floor(n) then
      return nil, 'N must be an integer between 1 and 10'
    end
    local headers = {}
    for i = 1, n do
      headers[i] = string.char(64 + i) -- A, B, C, ...
    end
    return headers
  end

  -- Otherwise, space-separated variable names
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
```

- [ ] **Step 2: Write the `TruthTable` command**

```lua
vim.api.nvim_create_user_command('TruthTable', function(opts)
  local headers, err = parse_truth_table_args(opts.args)
  if not headers then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local rows = generate_rows(#headers)
  local lines = format_table(headers, rows)

  -- Insert at cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1] - 1, false, lines)
end, { nargs = '+', desc = 'Generate a truth table' })
```

- [ ] **Step 3: Test manually**

Open a blank buffer, run `:TruthTable 3`. Verify output:

```
|  A  |  B  |  C  |
|:---:|:---:|:---:|
|  0  |  0  |  0  |
|  0  |  0  |  1  |
|  0  |  1  |  0  |
|  0  |  1  |  1  |
|  1  |  0  |  0  |
|  1  |  0  |  1  |
|  1  |  1  |  0  |
|  1  |  1  |  1  |
```

Then run `:TruthTable error timeout`. Verify headers are `error` and `timeout` with 4 data rows.

Test error cases: `:TruthTable 0`, `:TruthTable 11`, `:TruthTable error error`.

- [ ] **Step 4: Commit**

```bash
git add lua/custom/plugins/truth-table.lua
git commit -m "feat(truth-table): add :TruthTable command for table generation"
```

---

### Task 3: Table Detection

Implements the logic to find the truth table surrounding the cursor. Used by `:TruthTableExpand`, `:TruthTableDropRow`, and `:TruthTableDropColumn`.

**Files:**
- Modify: `lua/custom/plugins/truth-table.lua`

- [ ] **Step 1: Write `find_table` and `parse_table` functions**

`find_table()` returns the 1-indexed start and end line numbers of the table the cursor is in, or nil. `parse_table(start_line, end_line)` returns a structured representation: `{ headers, rows, start_line, end_line }`.

```lua
-- Check if a line looks like a table row: starts and ends with |
local function is_table_line(line)
  return line:match('^%s*|.*|%s*$') ~= nil
end

-- Check if a line is a separator row (e.g., |:---:|:---:|)
local function is_separator(line)
  -- Strip leading/trailing whitespace and outer pipes
  local inner = line:match('^%s*|(.+)|%s*$')
  if not inner then return false end
  -- Split on | and validate each cell
  for cell in (inner .. '|'):gmatch('(.-)%|') do
    if not cell:match('^%s*:?%-+:?%s*$') then
      return false
    end
  end
  return true
end

-- Split a table row into cell contents (trimmed)
local function split_row(line)
  local cells = {}
  local inner = line:match('^%s*|(.+)|%s*$')
  if not inner then return cells end
  for cell in (inner .. '|'):gmatch('(.-)%|') do
    cells[#cells + 1] = vim.trim(cell)
  end
  return cells
end

-- Find the table surrounding the cursor
-- Returns start_line, end_line (1-indexed) or nil
local function find_table()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cur_row = cursor[1]
  local total = vim.api.nvim_buf_line_count(0)

  local cur_line = vim.api.nvim_buf_get_lines(0, cur_row - 1, cur_row, false)[1]
  if not is_table_line(cur_line) then
    return nil
  end

  -- Scan upward
  local start_row = cur_row
  for row = cur_row - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if not is_table_line(line) then break end
    start_row = row
  end

  -- Scan downward
  local end_row = cur_row
  for row = cur_row + 1, total do
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if not is_table_line(line) then break end
    end_row = row
  end

  -- Validate: need at least heading + separator
  if end_row - start_row < 1 then return nil end

  -- Validate separator is line 2
  local sep_line = vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)[1]
  if not is_separator(sep_line) then return nil end

  return start_row, end_row
end

-- Parse a detected table into structured data
-- Returns { headers = {...}, rows = {{...}, ...}, start_line, end_line }
local function parse_table(start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local headers = split_row(lines[1])
  -- lines[2] is the separator, skip it
  local rows = {}
  for i = 3, #lines do
    rows[#rows + 1] = split_row(lines[i])
  end
  return {
    headers = headers,
    rows = rows,
    start_line = start_line,
    end_line = end_line,
  }
end
```

- [ ] **Step 2: Test manually**

Generate a table with `:TruthTable 2`, place cursor inside it, then run:

```
:lua local s, e = find_table(); print(s, e)
```

(The function is local so this won't work directly. To verify, temporarily add a test command or use `:TruthTableExpand` in the next task. The key verification happens in Task 4.)

- [ ] **Step 3: Commit**

```bash
git add lua/custom/plugins/truth-table.lua
git commit -m "feat(truth-table): add table detection and parsing"
```

---

### Task 4: Predicate Parser (Tokenizer + AST)

Implements the tokenizer and recursive descent parser for predicate expressions.

**Files:**
- Modify: `lua/custom/plugins/truth-table.lua`

- [ ] **Step 1: Write the tokenizer**

```lua
-- Tokenize a predicate string
-- Returns list of tokens: { type = "ident"|"op"|"paren"|"literal", value = string }
local function tokenize(input)
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

- [ ] **Step 2: Write the recursive descent parser**

```lua
-- Recursive descent parser
-- Returns AST node or nil + error message
local function parse_predicate(tokens)
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

- [ ] **Step 3: Write AST evaluation and heading generation**

```lua
-- Symbol mapping for heading display
local SYMBOLS = {
  ['and'] = '∧',
  ['or'] = '∨',
  ['xor'] = '⊕',
  ['not'] = '¬',
  ['!'] = '¬',
}

-- Evaluate an AST node given a row context (map of name -> 0/1)
local function eval_ast(node, ctx)
  if node.type == 'var' then
    return ctx[node.name]
  elseif node.type == 'literal' then
    return node.value
  elseif node.type == 'not' then
    return eval_ast(node.operand, ctx) == 0 and 1 or 0
  elseif node.type == 'and' then
    return (eval_ast(node.left, ctx) == 1 and eval_ast(node.right, ctx) == 1) and 1 or 0
  elseif node.type == 'or' then
    return (eval_ast(node.left, ctx) == 1 or eval_ast(node.right, ctx) == 1) and 1 or 0
  elseif node.type == 'xor' then
    return eval_ast(node.left, ctx) ~= eval_ast(node.right, ctx) and 1 or 0
  end
end

-- Generate heading string from AST (operators replaced with symbols)
local function ast_to_heading(node)
  if node.type == 'var' then
    return node.name
  elseif node.type == 'literal' then
    return tostring(node.value)
  elseif node.type == 'not' then
    return SYMBOLS['not'] .. ast_to_heading(node.operand)
  elseif node.type == 'and' or node.type == 'or' or node.type == 'xor' then
    return ast_to_heading(node.left) .. ' ' .. SYMBOLS[node.type] .. ' ' .. ast_to_heading(node.right)
  end
end
```

- [ ] **Step 4: Test parser manually**

After sourcing the file, test by temporarily exposing a debug command:

```
:TruthTable A B
```

Then proceed to Task 5 where `:TruthTableExpand` will exercise the full parser pipeline.

- [ ] **Step 5: Commit**

```bash
git add lua/custom/plugins/truth-table.lua
git commit -m "feat(truth-table): add predicate tokenizer, parser, and evaluator"
```

---

### Task 5: `:TruthTableExpand` Command

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

  -- Split predicates by comma
  local predicates = vim.split(opts.args, ',', { trimempty = true })
  if #predicates == 0 then
    vim.notify('Usage: :TruthTableExpand predicate1, predicate2, ...', vim.log.levels.WARN)
    return
  end

  -- Parse each predicate
  local parsed = {}
  for _, pred_str in ipairs(predicates) do
    pred_str = vim.trim(pred_str)
    local tokens, tok_err = tokenize(pred_str)
    if not tokens then
      vim.notify('Parse error: ' .. tok_err, vim.log.levels.ERROR)
      return
    end
    local ast, parse_err = parse_predicate(tokens)
    if not ast then
      vim.notify('Parse error in "' .. pred_str .. '": ' .. parse_err, vim.log.levels.ERROR)
      return
    end
    local var_err = validate_vars(ast, header_set)
    if var_err then
      vim.notify(var_err, vim.log.levels.ERROR)
      return
    end
    parsed[#parsed + 1] = { ast = ast, heading = ast_to_heading(ast) }
  end

  -- Extend headers and rows
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
      new_row[#new_row + 1] = tostring(eval_ast(p.ast, ctx))
    end
    new_rows[#new_rows + 1] = new_row
  end

  -- Replace the table
  local lines = format_table(new_headers, new_rows)
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

### Task 6: `:TruthTableDropRow` Command

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

  local lines = format_table(tbl.headers, tbl.rows)
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

### Task 7: `:TruthTableDropColumn` Command

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
  local lines = format_table(tbl.headers, tbl.rows)
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

### Task 8: Keymaps and Which-Key Group

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
