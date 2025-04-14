return {
  'ojroques/nvim-osc52',
  config = function()
    local osc52 = require 'osc52'

    osc52.setup {
      max_length = 0, -- Maximum length of selection (0 for no limit)
      silent = false, -- Disable message on successful copy
      trim = false, -- Trim surrounding whitespaces before copy
    }

    -- Only use this plugin when in SSH session with a TTY
    if vim.env.SSH_CONNECTION and vim.env.SSH_TTY and vim.env.SSH_TTY ~= '' then
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

      -- Don't override the entire clipboard provider
      -- Just use OSC52 for copying via TextYankPost autocmd
      -- This allows normal paste to work while copy goes through OSC52

      -- Manual mappings as fallback (from plugin documentation)
      vim.keymap.set('n', '<leader>c', require('osc52').copy_operator, { expr = true, desc = 'OSC52 copy operator' })
      vim.keymap.set('n', '<leader>cc', '<leader>c_', { remap = true, desc = 'OSC52 copy current line' })
      vim.keymap.set('v', '<leader>c', require('osc52').copy_visual, { desc = 'OSC52 copy selection' })

      -- vim.notify('OSC52 clipboard enabled (ojroques/nvim-osc52)', vim.log.levels.INFO)
    end
  end,
}

