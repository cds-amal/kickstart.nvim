return {
  dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins/jq-treesitter',
  name = 'jq-treesitter',
  ft = { 'json', 'yaml' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('custom.plugins.jq-treesitter.init').setup()
  end,
  cmd = { 'JqtList', 'JqtQuery', 'JqtPath', 'JqtMarkdownTable' },
}