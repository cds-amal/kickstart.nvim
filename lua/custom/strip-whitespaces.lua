vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.json', '*.lua', '*.sol', '*.tx', '*.yml' },
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
      lines[i] = line:gsub('%s+$', '')
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  end,
})
