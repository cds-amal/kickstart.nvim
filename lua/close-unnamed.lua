vim.api.nvim_create_user_command('CloseUnnamed', function()
  local count = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == '' and vim.bo[buf].buftype == '' then
      vim.api.nvim_buf_delete(buf, { force = true })
      count = count + 1
    end
  end
  vim.notify('Closed ' .. count .. ' unnamed buffers')
end, {})

vim.keymap.set('n', '<leader>bc', '<cmd>CloseUnnamed<CR>', { desc = 'Close unnamed buffers' })
