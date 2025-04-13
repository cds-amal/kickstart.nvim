-- ~/.config/nvim/lua/custom/plugins/ai/codecompanion.lua
return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  -- Lazy-load to ensure everything else is loaded first
  event = 'VeryLazy',
  config = function()
    -- Explicitly disable slash_commands before setup
    vim.g.codecompanion_disable_slash_commands = true

    local status_ok, codecompanion = pcall(require, 'codecompanion')
    if not status_ok then
      vim.notify('CodeCompanion failed to load', vim.log.levels.ERROR)
      return
    end

    codecompanion.setup {
      adapters = {
        llama3 = function()
          return require('codecompanion.adapters').extend('ollama', {
            name = 'llama3',
            schema = {
              model = {
                default = 'llama3:latest',
              },
              num_ctx = {
                default = 16384,
              },
              num_predict = {
                default = -1,
              },
            },
          })
        end,
      },
      -- Explicitly disable the slash_commands again
      slash_commands = {
        enabled = false,
      },
      -- Disable any telescope integrations
      telescope = {
        enabled = false,
      },
    }
  end,
}
