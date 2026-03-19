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
