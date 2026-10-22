-- Local plugin: hn.nvim, Hacker News as hn:// buffers. `:HN` is the front page, `:HN 8863` a
-- thread with each subthread a fold, `:HN search neovim plugins` a search with the site's three
-- controls (t, s, d in the buffer). Loaded eagerly so `:e hn://top` works in a fresh session.
return {
  dir = '~/dev/nvim-plugins/hn.nvim',
  main = 'hn',
  lazy = false,
  opts = {
    -- Every hn message goes through this, as rfc's do: snacks toasts float, so
    -- they leave cmdheight alone.
    notify = function(msg, level, opts)
      require('snacks').notifier.notify(msg, level, opts)
    end,
  },
}
