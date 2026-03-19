local core = require('custom.plugins.truth-table-core')

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
    local var_err = core.validate_vars(ast, header_set)
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

vim.api.nvim_create_user_command('TruthTableDropRow', function()
  local start_line, end_line = find_table()
  if not start_line then
    vim.notify('Cursor is not inside a truth table', vim.log.levels.WARN)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local cur_row = cursor[1]

  if cur_row <= start_line + 1 then
    vim.notify('Cannot drop heading or separator row', vim.log.levels.WARN)
    return
  end

  local tbl = parse_table(start_line, end_line)
  local row_idx = cur_row - start_line - 1
  table.remove(tbl.rows, row_idx)

  local lines = core.format_table(tbl.headers, tbl.rows)
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
end, { desc = 'Drop the current truth table row' })
