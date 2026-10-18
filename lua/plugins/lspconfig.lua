return { -- Main LSP configuration; implementation in lua/lsp.lua
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'b0o/schemastore.nvim',
    'saghen/blink.cmp',
  },
  config = function()
    require('lsp').setup()
  end,
}
