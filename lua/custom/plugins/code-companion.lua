-- selene: allow(mixed_table)

return {
  'olimorris/codecompanion.nvim',
  opts = {},
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    local plugin = require 'codecompanion'
    local adapter = require 'codecompanion.adapters'
    local llama3_adapter = function()
      return adapter.extend('ollama', {
        name = 'locallama3', -- Give this adapter a different name to differentiate it from the default ollama adapter
        schema = {
          model = {
            -- default = 'deepseek-r1:latest',
            default = 'qwen2.5-coder',
          },
          num_ctx = {
            default = 16384,
          },
          num_predict = {
            default = -1,
          },
        },
      })
    end

    plugin.setup {
      adapters = { locallama3 = llama3_adapter },
      strategies = {
        chat = {
          adapter = 'locallama3',
        },
        inline = {
          adapter = 'locallama3',
        },
      },
    }
  end,
}
