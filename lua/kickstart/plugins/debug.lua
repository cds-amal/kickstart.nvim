-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Modern debugging UI (unified sidebar)
    { 'igorlfs/nvim-dap-view', opts = { auto_toggle = true } },

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    'mfussenegger/nvim-dap',
    -- 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'},
    'theHamsta/nvim-dap-virtual-text',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle dap-view sidebar
    {
      '<F7>',
      '<cmd>DapViewToggle<cr>',
      desc = 'Debug: Toggle dap-view',
    },
    -- Variable inspection: hover under cursor (dap.ui.widgets float)
    {
      '<leader>dk',
      function()
        require('dap.ui.widgets').hover()
      end,
      mode = { 'n', 'v' },
      desc = 'Debug: Inspect variable under cursor',
    },
    -- Add watch expression (word under cursor, or visual selection)
    {
      '<leader>de',
      '<cmd>DapViewWatch<cr>',
      mode = { 'n', 'v' },
      desc = 'Debug: Add watch expression',
    },
    -- Evaluate raw/native LLDB expression via watch
    {
      '<leader>dE',
      function()
        local expr = vim.fn.input('LLDB expr: ')
        if expr ~= '' then
          vim.cmd('DapViewWatch /nat expr -R -- ' .. expr)
        end
      end,
      desc = 'Debug: Raw LLDB eval (watch)',
    },
    -- Jump to REPL view
    {
      '<leader>dr',
      '<cmd>DapViewJump repl<cr>',
      desc = 'Debug: Jump to REPL',
    },
    -- Scopes floating window (quick variable overview)
    {
      '<leader>ds',
      function()
        require('dap.ui.widgets').centered_float(require('dap.ui.widgets').scopes)
      end,
      desc = 'Debug: Scopes (floating)',
    },
  },
  config = function()
    local dap = require 'dap'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {
        -- Don't let mason handle delve, we'll use nvim-dap-go
        delve = function() end,
      },

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'deno',
        'codelldb', -- Rust debugger
      },
    }

    require('nvim-dap-virtual-text').setup()

    -- Change breakpoint icons
    -- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    -- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    -- local breakpoint_icons = vim.g.have_nerd_font
    --     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
    --   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    -- for type, icon in pairs(breakpoint_icons) do
    --   local tp = 'Dap' .. type
    --   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
    --   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    -- end

    -- Enable breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font
        and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    -- Float styling: make DAP eval/hover floats readable
    vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'Normal' })
    vim.api.nvim_set_hl(0, 'FloatBorder', { link = 'Comment' })

    -- Rust LLDB pretty-printers (improves &str, Vec, HashMap display)
    local rust_lldb = vim.fn.expand('~/.rustup/toolchains/1.88.0-aarch64-apple-darwin/lib/rustlib/etc')
    dap.configurations.rust = {
      {
        name = 'Debug (with Rust formatters)',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        initCommands = {
          ('command script import %s/lldb_lookup.py'):format(rust_lldb),
          ('command source %s/lldb_commands'):format(rust_lldb),
        },
      },
    }

    -- Setup Go debugging with nvim-dap-go
    require('dap-go').setup()
  end,
}
