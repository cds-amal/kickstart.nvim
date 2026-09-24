-- selene:allow(mixed_table)

return {
  {
    -- Renders in a terminal split (kitty/ghostty images), so no browser and
    -- no per-instance server: several Neovim instances just each get a split.
    'blackhat-7/vellum.nvim',
    ft = 'markdown',
    keys = {
      { '<leader>mp', '<cmd>Vellum<cr>', desc = 'Markdown preview (toggle)' },
      {
        '<leader>mz',
        function()
          require('vellum').zoom()
        end,
        desc = 'Markdown zoom image at cursor',
      },
    },
    opts = {},
  },
}
