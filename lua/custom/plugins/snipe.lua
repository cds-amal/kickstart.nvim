return {
  'leath-dub/snipe.nvim',
  enabled = false, -- replaced by Snacks.picker.buffers (see snacks.lua)
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
