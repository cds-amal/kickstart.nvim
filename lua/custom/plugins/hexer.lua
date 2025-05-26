return {
  'cds-amal/hexer-nvim',
  name = 'hexer',
  lazy = false,
  config = function()
    local hex = require 'hexer'
    vim.keymap.set('n', '<leader>hh', hex.format_calldata, { desc = 'Expand Calldata' })
    vim.keymap.set('n', '<leader>ha', hex.format_calldata, { desc = 'Convert bytes to ascii' })
  end,
}
