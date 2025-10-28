return {
  dir = '/Users/amal/dev/tx/nvim',
  dependencies = {
    {
      'nvimdev/lspsaga.nvim',
      opts = {
        symbol_in_winbar = {
          enable = false,
        },
        definition = {
          save_pos = true, -- save the cursor position of definition preview
        },
      },
    },
  },
  config = function()
    -- Simpler setup that bypasses potentially broken modules
    vim.filetype.add {
      extension = { tx = 'txtx' },
    }

    -- Setup LSP directly without workspace/navigation
    local lsp = require 'txtx.lsp'
    lsp.setup {
      cmd = { 'txtx', 'lsp' },
      cmd_env = { RUST_LOG = 'debug' },
      on_attach = function(client, bufnr)
        -- Disable pull diagnostics (not implemented by txtx LSP)
        client.server_capabilities.diagnosticProvider = nil
        -- Simple LSP keybindings without navigation module
        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gp', '<cmd>Lspsaga peek_definition<CR>')
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)

        -- Workspace diagnostics (LSP 3.17)
        -- Shows diagnostics for ALL files in multi-file runbooks, not just current buffer
        -- This uses the workspace/diagnostic request to get diagnostics from unopened files
        vim.keymap.set('n', ',Q', function()
          vim.diagnostic.setqflist { open = true }
        end, { desc = 'Open workspace diagnostics quickfix list' })

        -- Alternative: buffer-only diagnostics (use ,q for current buffer only)
        -- vim.keymap.set('n', ',q', function()
        --   vim.diagnostic.setloclist { open = true }
        -- end, { desc = 'Open buffer diagnostics location list' })
      end,
    }

    vim.keymap.set('n', 'gd', '<cmd>Lspsaga finder def<CR>')
    -- Setup commands
    require('txtx.commands').setup()
  end,
}
