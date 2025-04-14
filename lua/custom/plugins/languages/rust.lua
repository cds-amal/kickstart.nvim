return {
  -- Rust debugging support
  {
    'mfussenegger/nvim-dap',
    ft = 'rust',
    dependencies = {
      'williamboman/mason.nvim',
    },
    config = function()
      local dap = require('dap')
      
      -- Configure codelldb adapter for Rust
      dap.adapters.codelldb = {
        type = 'server',
        port = '${port}',
        executable = {
          command = vim.fn.stdpath('data') .. '/mason/bin/codelldb',
          args = { '--port', '${port}' },
        },
      }
      
      -- Rust debugging configurations
      dap.configurations.rust = {
        {
          name = 'Launch',
          type = 'codelldb',
          request = 'launch',
          program = function()
            -- Try to find the compiled binary
            local cwd = vim.fn.getcwd()
            local target_dir = cwd .. '/target/debug/'
            
            -- Get the package name from Cargo.toml
            local cargo_toml = io.open(cwd .. '/Cargo.toml', 'r')
            if cargo_toml then
              local content = cargo_toml:read('*all')
              cargo_toml:close()
              local package_name = content:match('name%s*=%s*"([^"]+)"')
              if package_name then
                local binary_path = target_dir .. package_name:gsub('-', '_')
                if vim.fn.filereadable(binary_path) == 1 then
                  return binary_path
                end
              end
            end
            
            -- Fallback: ask user for the binary path
            return vim.fn.input('Path to executable: ', target_dir, 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          args = {},
          runInTerminal = false,
        },
        {
          name = 'Launch with arguments',
          type = 'codelldb',
          request = 'launch',
          program = function()
            local cwd = vim.fn.getcwd()
            local target_dir = cwd .. '/target/debug/'
            
            local cargo_toml = io.open(cwd .. '/Cargo.toml', 'r')
            if cargo_toml then
              local content = cargo_toml:read('*all')
              cargo_toml:close()
              local package_name = content:match('name%s*=%s*"([^"]+)"')
              if package_name then
                local binary_path = target_dir .. package_name:gsub('-', '_')
                if vim.fn.filereadable(binary_path) == 1 then
                  return binary_path
                end
              end
            end
            
            return vim.fn.input('Path to executable: ', target_dir, 'file')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          args = function()
            local args_string = vim.fn.input('Arguments: ')
            return vim.split(args_string, ' ')
          end,
          runInTerminal = false,
        },
        {
          name = 'Attach to process',
          type = 'codelldb',
          request = 'attach',
          pid = require('dap.utils').pick_process,
          args = {},
        },
        {
          name = 'Debug unit tests',
          type = 'codelldb',
          request = 'launch',
          cargo = {
            args = { 'test', '--no-run', '--lib' },
          },
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
      }
    end,
  },
  
  -- Install codelldb via Mason
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'codelldb' })
      return opts
    end,
  },
  
  -- Better Rust tools
  {
    'mrcjkb/rustaceanvim',
    version = '^5',
    lazy = false, -- This plugin is already lazy-loaded by filetype
    ft = { 'rust' },
    config = function()
      vim.g.rustaceanvim = {
        -- Plugin configuration
        tools = {},
        -- LSP configuration
        server = {
          on_attach = function(client, bufnr)
            -- You can add custom on_attach logic here if needed
          end,
          settings = {
            -- rust-analyzer settings
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
              },
              checkOnSave = {
                command = 'clippy',
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
              command = vim.fn.stdpath('data') .. '/mason/bin/codelldb',
              args = { '--port', '${port}' },
            },
          },
        },
      }
    end,
  },
}