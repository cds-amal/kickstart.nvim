return {
  'ojroques/nvim-osc52',
  config = function()
    local osc52 = require('osc52')
    
    osc52.setup {
      max_length = 0,  -- Maximum length of selection (0 for no limit)
      silent = false,  -- Disable message on successful copy
      trim = false,    -- Trim surrounding whitespaces before copy
    }
    
    -- Only use this plugin when in SSH session
    if vim.env.SSH_CONNECTION then
      -- Function to copy all yanks to system clipboard via OSC52
      local function copy()
        if vim.v.event.operator == 'y' then
          osc52.copy_register(vim.v.event.regname)
        end
      end
      
      -- Set up autocommand for ALL yank operations
      vim.api.nvim_create_autocmd('TextYankPost', {
        group = vim.api.nvim_create_augroup('osc52-clipboard', { clear = true }),
        callback = copy,
        desc = 'Copy yanked text to system clipboard using OSC52',
      })
      
      -- Override clipboard provider to use osc52
      vim.g.clipboard = {
        name = 'osc52',
        copy = {
          ['+'] = function(lines)
            osc52.copy(table.concat(lines, '\n'))
          end,
          ['*'] = function(lines)
            osc52.copy(table.concat(lines, '\n'))
          end,
        },
        paste = {
          ['+'] = function() return {}, 'v' end,
          ['*'] = function() return {}, 'v' end,
        },
      }
      
      -- Optional: Visual mode mapping for explicit copy
      vim.keymap.set('v', '<leader>c', function()
        osc52.copy_visual()
      end, { desc = 'Copy selection to clipboard using OSC52' })
      
      vim.notify('OSC52 clipboard enabled (ojroques/nvim-osc52)', vim.log.levels.INFO)
    end
  end,
}