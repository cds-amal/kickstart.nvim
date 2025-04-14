---@type LazyPluginSpec
return {
  name = 'jq-snap',
  dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins/jq-snap',
  lazy = false,

  config = function()
    vim.api.nvim_create_user_command('JqToNewBuffer', function()
      local input = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local json = table.concat(input, '\n')
      local output = vim.fn.systemlist('echo ' .. vim.fn.shellescape(json) .. ' | jq .')

      local new_buf = vim.api.nvim_create_buf(true, true)
      vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, output)
      vim.api.nvim_set_current_buf(new_buf)
      vim.bo[new_buf].filetype = 'json'
    end, {})

    vim.keymap.set('n', '<leader>jj', ':JqToNewBuffer<CR>', { desc = 'Run jq and open in new buffer' })
  end,
}
