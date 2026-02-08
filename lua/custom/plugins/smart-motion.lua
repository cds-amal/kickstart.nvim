return {
  'FluxxField/smart-motion.nvim',
  event = 'VeryLazy',
  config = function()
    require('smart-motion').setup {
      presets = {
        words = true,
        lines = true,
        search = true,
        delete = false,
        yank = false,
        change = false,
        paste = false,
        treesitter = true,
        diagnostics = true,
        git = true,
        quickfix = true,
        marks = true,
        misc = { ['.'] = false }, -- don't clobber Vim's repeat-last-edit
      },
    }

    -- The search preset hardcodes a `,` keymap for repeat-backward.
    -- Delete it since `,` is our leader key.
    pcall(vim.keymap.del, { 'n', 'v' }, ',')
  end,
}
