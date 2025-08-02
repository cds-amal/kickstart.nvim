return {
  'gbprod/yanky.nvim',
  enabled = false, -- TEMPORARILY DISABLED FOR TESTING
  opts = {},
  keys = {
    { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' } },
    { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' } },
    { 'gp', '<Plug>(YankyGPutAfter)', mode = { 'n', 'x' } },
    { 'gP', '<Plug>(YankyGPutBefore)', mode = { 'n', 'x' } },
    { '<leader>sy', '<cmd>Telescope yank_history<CR>', desc = '[S]earch [Y]ank history' },
    { '<c-p>', '<Plug>(YankyPreviousEntry)', mode = { 'n' } },
    { '<c-n>', '<Plug>(YankyNextEntry)', mode = { 'n' } },
    { ']p', '<Plug>(YankyPutIndentAfterLinewise)', desc = 'YankyPutIndentAfterLinewise', mode = { 'n' } },
    { '[p', '<Plug>(YankyPutIndentBeforeLinewise)', desc = 'YankyPutIndentBeforeLinewise', mode = { 'n' } },
    { ']P', '<Plug>(YankyPutIndentAfterLinewise)', desc = 'YankyPutIndentAfterLinewise', mode = { 'n' } },
    { '[P', '<Plug>(YankyPutIndentBeforeLinewise)', desc = 'YankyPutIndentBeforeLinewise', mode = { 'n' } },
    { '>p', '<Plug>(YankyPutIndentAfterShiftRight)', desc = 'YankyPutIndentAfterShiftRight', mode = { 'n' } },
    { '<p', '<Plug>(YankyPutIndentAfterShiftLeft)', desc = 'YankyPutIndentAfterShiftLeft', mode = { 'n' } },
    { '>P', '<Plug>(YankyPutIndentBeforeShiftRight)', desc = 'YankyPutIndentBeforeShiftRight', mode = { 'n' } },
    { '<P', '<Plug>(YankyPutIndentBeforeShiftLeft)', desc = 'YankyPutIndentBeforeShiftLeft', mode = { 'n' } },
    { '=p', '<Plug>(YankyPutAfterFilter)', desc = 'YankyPutAfterFilter', mode = { 'n' } },
    { '=P', '<Plug>(YankyPutBeforeFilter)', desc = 'YankyPutBeforeFilter', mode = { 'n' } },
  },
}
