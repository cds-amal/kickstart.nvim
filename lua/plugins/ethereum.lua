-- ethereum.nvim: EVM development suite. hexer's calldata tooling was merged
-- in, so this is the one eth plugin now; the pure domain lives in eth-core.
--
-- Only the calldata module is enabled here, preserving the old hexer
-- workflow on <leader>H: ,Hd decodes calldata to a named tree, ,Hf formats
-- it into 32-byte words, ,Ha dumps hex as ASCII. Enable the other modules
-- (address, cast, scratch, receipts, trace, etherscan) in setup when ready.
return {
  dir = '~/dev/nvim-plugins/ethereum.nvim/',
  dependencies = { { dir = '~/dev/nvim-plugins/eth-core/' } },
  cmd = { 'EthDecodeCalldata', 'EthFormatCalldata', 'EthBytesToAscii' },
  keys = {
    { '<leader>Hd', '<cmd>EthDecodeCalldata<cr>', mode = { 'n', 'v' }, desc = 'Eth: [d]ecode calldata' },
    { '<leader>Hf', '<cmd>EthFormatCalldata<cr>', mode = { 'n', 'v' }, desc = 'Eth: [f]ormat calldata' },
    { '<leader>Ha', '<cmd>EthBytesToAscii<cr>', mode = { 'n', 'v' }, desc = 'Eth: hex to [a]scii' },
  },
  config = function()
    require('ethereum').setup({
      -- calldata only for now; flip these on as each module is adopted
      address = false,
      cast = false,
      receipts = false,
      scratch = false,
      trace = false,
      etherscan = false,
    })
  end,
}
