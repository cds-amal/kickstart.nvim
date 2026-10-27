-- Local plugin: rssfeedr, a feed reader. The feeds live in ~/.config/nvim/rssfeedr.md (a heading is a
-- category, a link line is a feed; paste a bare URL under a heading and :w names it once the river has
-- fetched it). `:Rssfeedr` is the river over every feed, `:Rssfeedr feeds` the feed file. Loaded eagerly
-- so `:e rssfeedr://river` works in a fresh session.
return {
  dir = '~/dev/nvim-plugins/rssfeedr',
  lazy = false,
  keys = {
    { '<leader>fr', '<cmd>Rssfeedr<cr>', desc = 'rssfeedr: the river' },
    { '<leader>ff', '<cmd>Rssfeedr feeds<cr>', desc = 'rssfeedr: the feed file' },
  },
}
