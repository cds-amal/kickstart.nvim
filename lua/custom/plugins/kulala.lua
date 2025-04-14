-- selene: allow(mixed_table)

return {
  'mistweaverco/kulala.nvim',
  keys = {
    {
      '<leader>Rs',
      function()
        require('kulala').run()
      end,
      desc = '[R]equest [S]end request',
      mode = 'n',
    },
    {
      '<leader>Ra',
      function()
        require('kulala').run_all()
      end,
      desc = 'Send all requests',
      mode = 'n',
    },
    {
      '<leader>Rb',
      function()
        require('kulala').scratchpad()
      end,
      desc = 'Open scratchpad',
      mode = 'n',
    },
    {
      '<leader>Rr',
      function()
        require('kulala').replay()
      end,
      desc = 'Replay last request',
      mode = 'n',
    },
    {
      '<leader>Rt',
      function()
        require('kulala').toggle_view()
      end,
      desc = 'Toggle headers/body',
      mode = 'n',
    },
  },
  ft = { 'http', 'rest' },
  opts = {
    global_keymaps = true,
    -- Add other options as needed
  },
}
