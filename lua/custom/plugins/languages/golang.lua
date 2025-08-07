-- selene:allow(mixed_table)
M = {}

M.go = {
  'ray-x/go.nvim',
  dependencies = { -- optional packages
    'ray-x/guihua.lua',
    'neovim/nvim-lspconfig',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('go').setup({
      -- Disable go.nvim's LSP setup to avoid conflicts with native gopls
      lsp_cfg = false,
      -- Enable other useful features
      lsp_gofumpt = true,
      dap_debug = true,
      -- Use native code actions from gopls
      lsp_codelens = true,
      diagnostic = {
        hdlr = false, -- Use native diagnostics
      },
      -- Keymaps
      lsp_keymaps = false, -- Don't override LSP keymaps
    })
  end,
  event = { 'CmdlineEnter' },
  ft = { 'go', 'gomod' },
  build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
}

-- convert map to array for lazygit
return {
  M.go,
}
