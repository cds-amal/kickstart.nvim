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
