return {
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter', branch = 'main', build = ':TSUpdate' },
    },
    config = function()
      require('nvim-treesitter-textobjects').setup {
        select = {
          lookahead = true,
          selection_modes = {
            ['@parameter.outer'] = 'v', -- charwise
            ['@function.outer'] = 'V', -- linewise
            ['@class.outer'] = '<c-v>', -- blockwise
          },
          include_surrounding_whitespace = false,
        },
      }

      -- Select keymaps
      local select = require('nvim-treesitter-textobjects.select').select_textobject
      vim.keymap.set({ 'x', 'o' }, 'af', function() select('@function.outer', 'textobjects') end, { desc = 'outer function' })
      vim.keymap.set({ 'x', 'o' }, 'if', function() select('@function.inner', 'textobjects') end, { desc = 'inner function' })
      vim.keymap.set({ 'x', 'o' }, 'ac', function() select('@class.outer', 'textobjects') end, { desc = 'outer class' })
      vim.keymap.set({ 'x', 'o' }, 'ic', function() select('@class.inner', 'textobjects') end, { desc = 'inner class' })

      -- Swap keymaps
      local swap = require('nvim-treesitter-textobjects.swap')
      vim.keymap.set('n', '<leader>a', function() swap.swap_next('@parameter.inner') end, { desc = 'Swap next parameter' })
      vim.keymap.set('n', '<leader>A', function() swap.swap_previous('@parameter.inner') end, { desc = 'Swap previous parameter' })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    enabled = false, -- disabled until it supports Neovim 0.12
  },
}
