return {
  'cds-io/jq-treesitter.nvim',
  ft = { 'json', 'yaml' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('jq-treesitter').setup()
  end,
}
