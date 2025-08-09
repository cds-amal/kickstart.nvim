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
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
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
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
    -- Additional debugging keymaps
    {
      '<F4>',
      function()
        require('dap').terminate()
      end,
      desc = 'Debug: Terminate',
    },
    {
      '<F6>',
      function()
        require('dap').repl.open()
      end,
      desc = 'Debug: Open REPL',
    },
    {
      '<leader>dr',
      function()
        require('dap').restart()
      end,
      desc = 'Debug: Restart',
    },
    {
      '<leader>dl',
      function()
        require('dap').run_last()
      end,
      desc = 'Debug: Run Last',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<leader>do',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<leader>dO',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>db',
      function()
        require('dap').step_back()
      end,
      desc = 'Debug: Step Back',
    },
    {
      '<leader>dc',
      function()
        require('dap').run_to_cursor()
      end,
      desc = 'Debug: Run to Cursor',
    },
    {
      '<leader>dh',
      function()
        require('dap.ui.widgets').hover()
      end,
      desc = 'Debug: Hover Variables',
    },
    {
      '<leader>dp',
      function()
        require('dap.ui.widgets').preview()
      end,
      desc = 'Debug: Preview',
    },
    {
      '<leader>df',
      function()
        local widgets = require('dap.ui.widgets')
        widgets.centered_float(widgets.frames)
      end,
      desc = 'Debug: Frames',
    },
    {
      '<leader>ds',
      function()
        local widgets = require('dap.ui.widgets')
        widgets.centered_float(widgets.scopes)
      end,
      desc = 'Debug: Scopes',
    },
    -- Go-specific debugging
    {
      '<leader>dt',
      function()
        require('dap-go').debug_test()
      end,
      desc = 'Debug: Go Test (at cursor)',
    },
    {
      '<leader>dT',
      function()
        require('dap-go').debug_last_test()
      end,
      desc = 'Debug: Go Last Test',
    },
    {
      '<leader>dg',
      function()
        local dap = require('dap')
        -- Use the first configuration (Debug)
        if dap.configurations.go and dap.configurations.go[1] then
          dap.run(dap.configurations.go[1])
        else
          vim.notify('Go debug configuration not found', vim.log.levels.ERROR)
        end
      end,
      desc = 'Debug: Go Current File',
    },
    {
      '<leader>dd',
      function()
        local dap = require('dap')
        vim.notify('DAP status: ' .. vim.inspect(dap.status()), vim.log.levels.INFO)
        if dap.session() then
          vim.notify('Active session found', vim.log.levels.INFO)
        else
          vim.notify('No active session', vim.log.levels.WARN)
        end
      end,
      desc = 'Debug: Check Status',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {
        -- Override the default handler for Go
        delve = function(config)
          -- Let nvim-dap-go handle the adapter setup
          -- We'll configure it later
        end,
      },

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'deno',
      },
    }

    require('nvim-dap-virtual-text').setup()

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
      layouts = {
        {
          elements = {
            { id = 'scopes', size = 0.25 },
            { id = 'breakpoints', size = 0.25 },
            { id = 'stacks', size = 0.25 },
            { id = 'watches', size = 0.25 },
          },
          size = 40,
          position = 'left',
        },
        {
          elements = {
            { id = 'repl', size = 0.5 },
            { id = 'console', size = 0.5 },
          },
          size = 10,
          position = 'bottom',
        },
      },
      floating = {
        max_height = nil,
        max_width = nil,
        border = 'rounded',
        mappings = {
          close = { 'q', '<Esc>' },
        },
      },
      windows = { indent = 1 },
      render = {
        max_type_length = nil,
        max_value_lines = 100,
      },
    }

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

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Setup Go debugging manually to ensure it works
    dap.adapters.go = {
      type = 'server',
      port = '${port}',
      executable = {
        command = 'dlv',
        args = { 'dap', '-l', '127.0.0.1:${port}' },
        detached = vim.fn.has 'win32' == 0,
      },
    }

    -- Configure Go debugging
    dap.configurations.go = {
      {
        type = 'go',
        name = 'Debug',
        request = 'launch',
        program = '${file}',
        stopOnEntry = false,
      },
      {
        type = 'go',
        name = 'Debug (Stop on Entry)',
        request = 'launch',
        program = '${file}',
        stopOnEntry = true,
      },
      {
        type = 'go',
        name = 'Debug Package',
        request = 'launch',
        program = '${fileDirname}',
      },
      {
        type = 'go',
        name = 'Debug Test',
        request = 'launch',
        mode = 'test',
        program = '${file}',
      },
      {
        type = 'go',
        name = 'Debug Test (go.mod)',
        request = 'launch',
        mode = 'test',
        program = './${relativeFileDirname}',
      },
    }

    -- Now setup nvim-dap-go for additional features
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        detached = vim.fn.has 'win32' == 0,
        -- Time to wait for delve to initialize (ms)
        initialize_timeout_sec = 20,
        -- Port to start delve debugger on
        port = '${port}',
      },
    }

    -- Add debug output for session events
    dap.listeners.after['event_initialized']['debug_log'] = function()
      vim.notify('Debug session started', vim.log.levels.INFO)
    end
    
    dap.listeners.after['event_terminated']['debug_log'] = function()
      vim.notify('Debug session terminated', vim.log.levels.INFO)
    end
    
    dap.listeners.after['event_exited']['debug_log'] = function()
      vim.notify('Debug session exited', vim.log.levels.INFO)
    end
    
    -- Log adapter errors
    dap.listeners.before['event_output']['debug_log'] = function(session, body)
      if body.category == 'stderr' then
        vim.notify('Debug stderr: ' .. body.output, vim.log.levels.WARN)
      end
    end
  end,
}
