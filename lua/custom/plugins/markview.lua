-- For `plugins/markview.lua` users.
return {
  'OXY2DEV/markview.nvim',
  lazy = false,

  -- For blink.cmp's completion
  -- source
  dependencies = {
    'saghen/blink.cmp',
    -- NOTE: nvim-treesitter removed from dependencies to ensure
    -- markview loads BEFORE treesitter (prevents syntax highlighting conflicts)
  },
}
