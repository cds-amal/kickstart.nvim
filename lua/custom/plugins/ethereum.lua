return {
  'ethereum.nvim',
  dir = '~/dev/nvim-plugins/ethereum.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim', -- Optional but recommended
    'tpope/vim-repeat', -- For dot-repeat support
  },
  config = function()
    require('ethereum').setup {
      -- Setup all modules with their defaults
      address = {
        -- Address label configuration (from eth-helper)
        addresses = {},
      },
      cast = {
        -- Cast command configuration
        use_scratch_pad = true, -- Default
        scratch_window_type = 'vsplit', -- Default
        rpc_url = 'http://localhost:8545',
      },
      calldata = {
        -- Calldata formatting configuration
        decode_with_cast = true,
      },
      scratch = {
        window_type = 'vsplit',
        auto_scroll = true,
      },
    }
  end,
}
