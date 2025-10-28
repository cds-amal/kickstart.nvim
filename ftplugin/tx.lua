vim.bo.makeprg = 'txtx lint --format quickfix'
vim.bo.errorformat = '%f:%l:%c: E: %m'

local wk = require 'which-key'

wk.add {
  { '<leader>tx', group = 'txtx' },
  { '<leader>txl', '<cmd>make<CR><cmd>copen<CR>', desc = 'Lint' },
}
