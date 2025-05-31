return {
  'eth-helper',
  dir = vim.fn.expand '~/dev/nvim-plugins/eth-helper/',
  lazy = false,
  config = function()
    require('eth-helper').setup {
      scan_on = {},
      -- addresses = {
      --   ['0x093Ddc1DD7784029b32d44F0C11B29AEb8232cc9'] = 'Heidi',
      --   ['0x7aBF46564cfd4d67E36DC8fB5DeF6a1162EBaF6b'] = 'Grace',
      --   ['0x6BeA16caD793AD7F162A19cB025b0248E895a708'] = 'Ivan',
      -- },
    }
  end,

  -- keys = {
  --   { '<leader>el', '<cmd>EthLabelList<CR>', desc = 'List Ethereum addresses' },
  --   { '<leader>ea', '<cmd>EthLabelAdd<CR>', desc = 'Add Ethereum label' },
  -- },
}
