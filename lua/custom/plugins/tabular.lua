return {
  'godlygeek/tabular',
  cmd = { 'Tabularize' },
  keys = {
    {
      '<leader>tm',
      function()
        local start_pos = vim.fn.getpos("'<")[2]
        local end_pos = vim.fn.getpos("'>")[2]

        -- Convert tab-separated lines to pipe-separated markdown rows
        for lnum = start_pos, end_pos do
          local line = vim.fn.getline(lnum)
          -- Split on tabs
          local fields = vim.split(line, '\t')
          -- Reconstruct with Markdown pipe format
          line = '| ' .. table.concat(fields, ' | ') .. ' |'
          vim.fn.setline(lnum, line)
        end

        -- Align the newly formatted lines
        vim.cmd(start_pos .. ',' .. end_pos .. 'Tabularize /|/')
      end,
      mode = 'v',
      desc = 'TSV to Markdown Table (Tabularize)',
    },
  },
}
