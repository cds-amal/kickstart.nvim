return {
  'heilgar/nvim-http-client',
  dependencies = { 'nvim-lua/plenary.nvim', 'hrsh7th/nvim-cmp', 'nvim-telescope/telescope.nvim' },
  ft = { 'http', 'rest' },
  config = function()
    require('http_client').setup {
      -- default or customize as desired
      create_keybindings = true,
      keybindings = {
        -- :HttpCopyCurl
        copy_curl = '<leader>hc',
      },
    }
  end,
}
