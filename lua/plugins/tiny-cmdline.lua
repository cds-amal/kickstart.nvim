-- The plugin auto-initializes on UIEnter, but an explicit setup is the only way to hand it
-- the blink adapter (a function, so it can't live in vim.g.tiny_cmdline before load).
return {
  'rachartier/tiny-cmdline.nvim',
  init = function()
    -- Both must be in place before the plugin initializes, or the cmdline stays at the bottom.
    require('vim._core.ui2').enable {}
    vim.o.cmdheight = 0
  end,
  opts = function()
    return {
      width = { value = '70%' },
      -- blink.cmp positions its own menu; the adapter keeps it under the floating cmdline.
      on_reposition = require('tiny-cmdline').adapters.blink,
    }
  end,
}
