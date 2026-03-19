# Truth Table Plugin Design

A standalone local Neovim plugin (`lua/custom/plugins/truth-table.lua`) that generates, expands, and manipulates markdown truth tables inline.

## Scope

In scope: table generation, predicate expansion with logical operators, row/column deletion, keymaps.

Out of scope: truth table simplification, Karnaugh maps, export to other formats, integration with external tools.

## Commands

### `:TruthTable {args}`

Generates a truth table and inserts it at the cursor position.

`{args}` is either:
- A number N (1-10): creates columns named A, B, C, ... up to the Nth letter. N > 10 is refused (2^10 = 1024 rows is already large).
- A space-separated list of variable names: creates columns with those names. Duplicate names are refused.

Variable names (IDENT) must match `[A-Za-z_][A-Za-z0-9_]*`. This applies to both `:TruthTable` names and `:TruthTableExpand` column references.

Rows enumerate all 2^N combinations in binary counting order. Column index 1 (leftmost) has bit weight 2^(N-1); column index N (rightmost) has bit weight 2^0 (LSB).

Example: `:TruthTable error timeout` produces:

```
| error | timeout |
|:-----:|:-------:|
|   0   |    0    |
|   0   |    1    |
|   1   |    0    |
|   1   |    1    |
```

### `:TruthTableExpand {predicates}`

Appends one or more computed columns to an existing truth table. The cursor must be inside the table.

`{predicates}` is a comma-separated list of logical expressions referencing existing column names.

Supported operators (with their heading symbols):

| Keyword | Symbol | Type | Precedence (high to low) |
|---------|--------|------|--------------------------|
| `not` / `!` | `¬` | Unary | 1 (highest) |
| `and` | `∧` | Binary | 2 |
| `or` | `∨` | Binary | 3 |
| `xor` | `⊕` | Binary | 4 (lowest) |

Parentheses override precedence.

Example: with a table containing `error` and `timeout` columns, `:TruthTableExpand error and timeout, error or timeout` appends two columns with headings `error ∧ timeout` and `error ∨ timeout`, values computed per row.

### `:TruthTableDropRow`

Removes the data row under the cursor. Refuses to operate on the heading row or the separator row.

### `:TruthTableDropColumn`

Removes the column the cursor is positioned in (detected by counting `|` delimiters up to the cursor column). Removes the column from the heading, separator, and all data rows. Refuses if it is the only remaining column.

## Table Detection

When a command needs to find the current table:

1. Check that the current line matches `^%s*|.*|%s*$`
2. Scan upward from the cursor to find the first non-matching line; the line after it is the table start
3. Scan downward to find the last matching line; that is the table end
4. Line 1 of the table is the heading, line 2 is the separator (each cell between `|` delimiters validated against `^%s*:?%-+:?%s*$`), lines 3+ are data rows

## Predicate Parser

A recursive descent parser that produces a simple AST from predicate strings.

### Grammar

```
expr     := xor_expr
xor_expr := or_expr ('xor' or_expr)*
or_expr  := and_expr ('or' and_expr)*
and_expr := unary ('and' unary)*
unary    := ('not' | '!') unary | atom
atom     := IDENT | '(' expr ')' | '0' | '1'
```

IDENT matches `[A-Za-z_][A-Za-z0-9_]*` (case-sensitive). Tokens are delimited by whitespace, `!`, `(`, and `)`. The `!` character acts as both a token boundary and an operator, so `!error` tokenizes as `!` followed by `error`.

### AST Nodes

- `{ type = "var", name = "error" }`
- `{ type = "literal", value = 0 }` or `{ type = "literal", value = 1 }`
- `{ type = "not", operand = <node> }`
- `{ type = "and"|"or"|"xor", left = <node>, right = <node> }`

### Evaluation

Walk the AST with a row context (map of column name to 0/1 value). Each node returns 0 or 1.

### Heading Generation

Walk the AST to produce the display string, substituting operator keywords with their Unicode symbols. Variable names and parentheses are preserved as-is. No implicit parentheses are added to headings; only user-supplied parentheses appear in the output.

## Table Formatting

All cells are padded to equal width per column and center-aligned. The separator row uses `:---:` style (centered) with dashes matching the column width.

After any mutation (expand, drop), the entire table is reformatted to maintain alignment.

Each command is a single undo step (`vim.cmd('undojoin')` where needed to group multiple buffer writes).

## Keymaps

All keymaps are normal mode, grouped under `<leader>tt` with which-key group `[T]ruth Table`:

| Keymap | Command | Description |
|--------|---------|-------------|
| `<leader>ttn` | `:TruthTable` | New truth table (prompts via `vim.ui.input`) |
| `<leader>tte` | `:TruthTableExpand` | Expand with predicate (prompts via `vim.ui.input`) |
| `<leader>ttr` | `:TruthTableDropRow` | Drop current row |
| `<leader>ttc` | `:TruthTableDropColumn` | Drop current column |

## File Location

`lua/custom/plugins/truth-table.lua`

Single file, returns `{}` for lazy.nvim (same pattern as `rot13-comment.lua`). All logic is self-contained with no external dependencies.

## Error Handling

- `:TruthTable 0` or `:TruthTable 11`: notify with warning, do nothing
- `:TruthTable` with duplicate variable names: notify and refuse
- `:TruthTableExpand` with unknown column name: notify which name was unrecognized
- `:TruthTableExpand` with syntax error in predicate: notify with the parse error
- `:TruthTableDropRow` on heading/separator: notify "Cannot drop heading or separator row"
- `:TruthTableDropColumn` on last column: notify "Cannot drop the only column"
- Any command requiring a table when cursor is not in one: notify "Cursor is not inside a truth table"
