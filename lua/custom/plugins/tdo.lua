return {
  '2kabhishek/tdo.nvim',
  dependencies = '2kabhishek/pickme.nvim',
  cmd = { 'Tdo' },
  -- Add more keybindings you need for lazy loading from the table below
  keys = { '<leader>NN', '<leader>NF', '<leader>NH', '<leader>NL', '<leader>NT', '<leader>NX', '[s', ']s' },
  opts = {}, -- Required if you are not calling tdo.setup setup manually, you can add your config here
}
