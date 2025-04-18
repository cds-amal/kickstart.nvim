return {
  'mistweaverco/kulala.nvim',
  keys = {
    { '<leader>rs', desc = 'Send request' },
    { '<leader>ra', desc = 'Send all requests' },
    { '<leader>rb', desc = 'Open scratchpad' },
  },
  ft = { 'http', 'rest' },
  opts = {
    -- your configuration comes here
    global_keymaps = true,
  },
}
