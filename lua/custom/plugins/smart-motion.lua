return {
  'FluxxField/smart-motion.nvim',
  event = 'VeryLazy',
  config = function()
    require('smart-motion').setup {
      presets = {
        words = true,
        lines = true,
        search = true,
        delete = true,
        yank = true,
        change = true,
        paste = true,
        treesitter = true,
        diagnostics = true,
        git = true,
        quickfix = true,
        marks = true,
        misc = true,
      },
    }

    -- The search preset hardcodes a `,` keymap for repeat-backward.
    -- Delete it since `,` is our leader key.
    pcall(vim.keymap.del, { 'n', 'v' }, ',')
  end,
}
