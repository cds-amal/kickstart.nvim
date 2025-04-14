return {
  'leath-dub/snipe.nvim',
  keys = {
    {
      'gb',
      function()
        require('snipe').open_buffer_menu()
      end,
      desc = '[G]et [B]uffers and snipe',
    },
  },
  opts = {
    ui = {
      position = 'center',
    },
  },
}
