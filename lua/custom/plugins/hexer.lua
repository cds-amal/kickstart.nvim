-- selene: allow(mixed_table)

return {
  -- 'cds-amal/hexer-nvim',
  dir = '~/dev/nvim-plugins/hexer-nvim',
  dev = true,
  name = 'hexer',
  lazy = false,
  config = function()
    local hex = require 'hexer'
    vim.keymap.set('n', '<leader>hf', hex.format_calldata, { desc = '[H]exer [F]ormat Calldata' })
    vim.keymap.set('n', '<leader>ha', hex.bytes_to_ascii, { desc = '[H]exer bytes to [A]scii' })
    vim.keymap.set('n', '<leader>hB', hex.abi_decode, { desc = '[H]exer decode to A[B]I' })
  end,
}
