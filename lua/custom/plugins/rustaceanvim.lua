return {
  'mrcjkb/rustaceanvim',
  version = '^5',
  lazy = false,
  ft = { 'rust' },
  config = function()
    local codelldb_path = vim.fn.stdpath('data') .. '/mason/bin/codelldb'
    local liblldb_path = vim.fn.stdpath('data') .. '/mason/packages/codelldb/extension/lldb/lib/liblldb.dylib'

    -- LSP toggle state: 'rust-analyzer' or 'rs-commentary'
    vim.g.rust_lsp_active = 'rs-commentary'

    local rs_commentary_path = vim.fn.expand('$HOME/oss/rs-commentary/target/release/rs-commentary')

    -- Start rs-commentary for a buffer
    local function start_rs_commentary(bufnr)
      bufnr = bufnr or vim.api.nvim_get_current_buf()
      vim.lsp.start({
        name = 'rs-commentary',
        cmd = { 'sh', '-c', rs_commentary_path .. ' 2>> /tmp/rs-commentary-log' },
        root_dir = vim.fs.root(bufnr, { 'Cargo.toml', '.git' }),
        capabilities = require('blink.cmp').get_lsp_capabilities(),
        on_attach = function()
          vim.lsp.inlay_hint.enable(true)
        end,
      })
    end

    -- Toggle function
    local function toggle_rust_lsp()
      local bufnr = vim.api.nvim_get_current_buf()

      -- Stop current LSP clients for this buffer
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      for _, client in ipairs(clients) do
        if client.name == 'rust-analyzer' or client.name == 'rs-commentary' then
          client:stop()
        end
      end

      -- Toggle the active LSP
      if vim.g.rust_lsp_active == 'rust-analyzer' then
        vim.g.rust_lsp_active = 'rs-commentary'
        start_rs_commentary()
        vim.notify('Switched to rs-commentary', vim.log.levels.INFO)
      else
        vim.g.rust_lsp_active = 'rust-analyzer'
        -- Trigger FileType to let rustaceanvim auto-attach
        vim.cmd('doautocmd FileType rust')
        vim.notify('Switched to rust-analyzer', vim.log.levels.INFO)
      end
    end

    -- Global keymap for toggling (works in any Rust buffer)
    vim.keymap.set('n', '<leader>rL', toggle_rust_lsp, { desc = 'Rust: Toggle LSP (rust-analyzer/rs-commentary)' })

    -- Auto-start rs-commentary for Rust files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'rust',
      callback = function()
        if vim.g.rust_lsp_active == 'rs-commentary' then
          start_rs_commentary()
        end
      end,
    })

    -- Commands for rs-commentary
    vim.api.nvim_create_user_command('RsCommentaryStart', function()
      start_rs_commentary()
    end, {})

    vim.api.nvim_create_user_command('RsCommentaryStop', function()
      for _, client in ipairs(vim.lsp.get_clients({ name = 'rs-commentary' })) do
        client:stop()
      end
    end, {})

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
        auto_attach = function()
          -- Only auto-attach rust-analyzer if it's the active LSP
          return vim.g.rust_lsp_active == 'rust-analyzer'
        end,
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

          -- Toggle inlay hints
          map('<leader>ri', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
          end, 'Toggle Inlay Hints')
        end,

        settings = {
          ['rust-analyzer'] = {
            completion = {
              callable = {
                snippets = 'fill_arguments',
              },
              postfix = {
                enable = true,
              },
            },
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
                enable = true,
              },
              closingBraceHints = {
                enable = true,
                minLines = 25,
              },
              closureReturnTypeHints = {
                enable = 'with_block',
              },
              lifetimeElisionHints = {
                enable = 'never',
                useParameterNames = false,
              },
              maxLength = 25,
              parameterHints = {
                enable = true,
              },
              reborrowHints = {
                enable = 'never',
              },
              renderColons = true,
              typeHints = {
                enable = true,
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
        configuration = {
          initCommands = {
            'command script import ' .. vim.fn.expand('~/.rustup/toolchains/1.88.0-aarch64-apple-darwin/lib/rustlib/etc/lldb_lookup.py'),
            'command source ' .. vim.fn.expand('~/.rustup/toolchains/1.88.0-aarch64-apple-darwin/lib/rustlib/etc/lldb_commands'),
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
