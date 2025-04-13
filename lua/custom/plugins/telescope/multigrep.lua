-- ~/.config/nvim/lua/custom/plugins/telescope/multigrep.lua
return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    local telescope = require 'telescope'

    -- Create a special multigrep picker
    local multigrep = function(opts)
      local pickers = require 'telescope.pickers'
      local finders = require 'telescope.finders'
      local conf = require('telescope.config').values

      -- Define file types to search in
      local file_types = { 'lua', 'go', 'js', 'ts', 'py' }
      local search_command = opts.search_command or 'rg'
      local search_args = {
        '--type=' .. table.concat(file_types, ' --type='),
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
        opts.search_pattern or '',
      }

      pickers
        .new(opts, {
          prompt_title = 'MultiGrep',
          finder = finders.new_oneshot_job({ search_command, unpack(search_args) }, {}),
          sorter = conf.generic_sorter(opts),
        })
        :find()
    end

    -- Register the function globally
    _G.multigrep = multigrep

    -- Add the command
    vim.api.nvim_create_user_command('MultiGrep', function(opts)
      multigrep { search_pattern = opts.args }
    end, { nargs = 1 })

    -- Add keymap
    vim.keymap.set('n', '<leader>mg', ':MultiGrep ', { noremap = true })

    -- Add this function as a telescope extension without modifying the core setup
    telescope.register_extension {
      exports = {
        multigrep = multigrep,
      },
    }
  end,
}
