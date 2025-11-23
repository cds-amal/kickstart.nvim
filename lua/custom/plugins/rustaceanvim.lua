return {
  'mrcjkb/rustaceanvim',
  version = '^5',
  lazy = false,
  ft = { 'rust' },
  config = function()
    local codelldb_path = vim.fn.stdpath('data') .. '/mason/bin/codelldb'
    local liblldb_path = vim.fn.stdpath('data') .. '/mason/packages/codelldb/extension/lldb/lib/liblldb.so'
    
    vim.g.rustaceanvim = {
      -- Plugin configuration
      tools = {
        hover_actions = {
          auto_focus = false,
        },
        test_executor = 'background', -- or 'termopen' for terminal
      },
      
      -- LSP configuration
      server = {
        on_attach = function(client, bufnr)
          -- Set keymaps for Rust-specific features
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc })
          end
          
          -- Rust-specific keymaps
          map('<leader>rc', function() vim.cmd.RustLsp('codeAction') end, 'Code Action')
          map('<leader>rd', function() vim.cmd.RustLsp('debuggables') end, 'Debuggables')
          map('<leader>rt', function() vim.cmd.RustLsp('testables') end, 'Testables')
          map('<leader>rr', function() vim.cmd.RustLsp('runnables') end, 'Runnables')
          map('<leader>re', function() vim.cmd.RustLsp('expandMacro') end, 'Expand Macro')
          map('<leader>rp', function() vim.cmd.RustLsp('rebuildProcMacros') end, 'Rebuild Proc Macros')
          map('<leader>rm', function() vim.cmd.RustLsp('moveItemUp') end, 'Move Item Up')
          map('<leader>rM', function() vim.cmd.RustLsp('moveItemDown') end, 'Move Item Down')
          map('<leader>rh', function() vim.cmd.RustLsp({ 'hover', 'actions' }) end, 'Hover Actions')
          map('<leader>rx', function() vim.cmd.RustLsp('explainError') end, 'Explain Error')
          map('<leader>ro', function() vim.cmd.RustLsp('openCargo') end, 'Open Cargo.toml')
          map('<leader>rg', function() vim.cmd.RustLsp('openDocs') end, 'Open Docs')
          map('<leader>rj', function() vim.cmd.RustLsp('joinLines') end, 'Join Lines')
          
          -- Debug specific test under cursor
          map('<leader>rD', function() vim.cmd.RustLsp({ 'debuggables', bang = true }) end, 'Debug Test')
        end,
        
        settings = {
          ['rust-analyzer'] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              runBuildScripts = true,
            },
            checkOnSave = true,
            check = {
              allFeatures = true,
              command = 'clippy',
              extraArgs = { '--no-deps' },
            },
            procMacro = {
              enable = true,
              ignored = {
                ['async-trait'] = { 'async_trait' },
                ['napi-derive'] = { 'napi' },
                ['async-recursion'] = { 'async_recursion' },
              },
            },
            diagnostics = {
              enable = true,
              experimental = {
                enable = true,
              },
            },
            inlayHints = {
              bindingModeHints = {
                enable = false,
              },
              chainingHints = {
                enable = false,  -- Reduced noise
              },
              closingBraceHints = {
                enable = true,
                minLines = 25,
              },
              closureReturnTypeHints = {
                enable = 'never',
              },
              lifetimeElisionHints = {
                enable = 'never',
                useParameterNames = false,
              },
              maxLength = 25,
              parameterHints = {
                enable = false,  -- Reduced noise
              },
              reborrowHints = {
                enable = 'never',
              },
              renderColons = true,
              typeHints = {
                enable = false,  -- Reduced noise - toggle with <leader>th
                hideClosureInitialization = false,
                hideNamedConstructor = false,
              },
            },
          },
        },
      },
      
      -- DAP configuration
      dap = {
        adapter = {
          type = 'server',
          port = '${port}',
          executable = {
            command = codelldb_path,
            args = { '--port', '${port}' },
          },
        },
      },
    }
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'mfussenegger/nvim-dap',
  },
}