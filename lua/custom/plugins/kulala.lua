return {
  'mistweaverco/kulala.nvim',
  keys = {
    {
      '<leader>Rs',
      function()
        require('kulala').run()
      end,
      desc = '[R]equest [S]end request',
    },
    {
      '<leader>Ra',
      function()
        require('kulala').run_all()
      end,
      desc = 'Send all requests',
    },
    {
      '<leader>Rb',
      function()
        require('kulala').scratchpad()
      end,
      desc = 'Open scratchpad',
    },
    {
      '<leader>Rr',
      function()
        require('kulala').replay()
      end,
      desc = 'Replay last request',
    },
    {
      '<leader>Rt',
      function()
        require('kulala').toggle_view()
      end,
      desc = 'Toggle headers/body',
    },
  },
  ft = { 'http', 'rest' },
  opts = {
    global_keymaps = true,
    -- Add other options as needed
  },
}
