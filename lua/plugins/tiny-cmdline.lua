return {
  'rachartier/tiny-cmdline.nvim',
  init = function()
    require('vim._core.ui2').enable {}
    vim.o.cmdheight = 0
    on_reposition = require('tiny-cmdline').adapters.blink
    width = {
      value = '70%',
    }
  end,
}
