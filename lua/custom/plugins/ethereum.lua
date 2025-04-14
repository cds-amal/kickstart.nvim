return {
  'ethereum.nvim',
  dir = '~/dev/nvim-plugins/ethereum.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim', -- Optional but recommended
    'tpope/vim-repeat', -- For dot-repeat support
  },
  lazy = true,
  config = function()
    -- Restore LSP keymaps for Rust files after Ethereum plugin loads
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'rust',
      callback = function()
        -- Restore LSP keymaps for Rust files
        vim.schedule(function()
          local bufnr = vim.api.nvim_get_current_buf()
          local opts = { buffer = bufnr, silent = true }

          -- Restore the LSP navigation keymaps
          vim.keymap.set('n', 'grd', require('telescope.builtin').lsp_definitions, vim.tbl_extend('force', opts, { desc = '[G]oto [D]efinition' }))
          vim.keymap.set('n', 'grr', require('telescope.builtin').lsp_references, vim.tbl_extend('force', opts, { desc = '[G]oto [R]eferences' }))
          vim.keymap.set('n', 'gri', require('telescope.builtin').lsp_implementations, vim.tbl_extend('force', opts, { desc = '[G]oto [I]mplementation' }))
          vim.keymap.set('n', 'grt', require('telescope.builtin').lsp_type_definitions, vim.tbl_extend('force', opts, { desc = '[G]oto [T]ype Definition' }))
          vim.keymap.set('n', 'grD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = '[G]oto [D]eclaration' }))
          vim.keymap.set('n', 'gra', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = '[G]oto Code [A]ction' }))
        end)
      end,
    })

    require('ethereum').setup {
      -- Setup all modules with their defaults
      address = {
        -- Address label configuration (from eth-helper)
        color_mode = 'address',
        addresses = {},
        scan_on = { '.eoa-mappings.yml' },
      },
      cast = {
        -- Cast command configuration
        output_mode = 'scratch', -- Replaces use_scratch_pad (options: 'scratch', 'buffer', 'float')
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
