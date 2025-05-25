return {
  {
    dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins/eth-explorer',
    name = 'ethereum-explorer',
    config = function()
      require('custom.plugins.eth-explorer.eth-explorer').setup()
    end,
  },
}
