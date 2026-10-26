-- rssfeed.nvim's own `select_feed` hard-requires telescope, which is not installed here; the
-- feed picker below goes through vim.ui.select (Snacks.picker owns it) and hands the chosen url
-- to the plugin's fetch/parse/display pipeline, which has no telescope dependency.
local function select_feed()
  local feeds = require('rssfeed.config').options.feeds
  vim.ui.select(feeds, {
    prompt = 'Select RSS Feed',
    format_item = function(feed)
      return feed.name
    end,
  }, function(feed)
    if feed then
      require('rssfeed').get_rss_feed(feed.url)
    end
  end)
end

return {
  '4DRIAN0RTIZ/rssfeed.nvim',
  dependencies = {
    'MunifTanjim/nui.nvim',
  },
  cmd = 'RSSFeed',
  config = function()
    require('rssfeed').setup {
      open_cmd = 'open',
      feeds = {
        { name = 'Dotfyle', url = 'https://dotfyle.com/neovim/plugins/rss.xml' },
        { name = 'HackerNews', url = 'https://hnrss.org/frontpage' },
        { name = 'Dev.to', url = 'https://dev.to/feed' },
        { name = 'TechCrunch', url = 'https://techcrunch.com/feed/' },
        { name = 'Smashing Magazine', url = 'https://www.smashingmagazine.com/feed/' },
        { name = 'CSS Tricks', url = 'https://css-tricks.com/feed/' },
        { name = 'HiperTextual', url = 'https://hipertextual.com/feed' },
        { name = 'Another neovim blog', url = 'https://blog.nerdware.ca/feed.xml' },
        { name = 'Computational Complexity', url = 'https://blog.computationalcomplexity.org/feeds/posts/default' },
        { name = 'Math JeremyKun', url = 'https://www.jeremykun.com/posts/index.xml' },
        { name = 'Math Science Daily', url = 'https://www.sciencedaily.com/rss/computers_math/mathematics.xml' },
        { name = 'Hidden Brain', url = 'https://feeds.simplecast.com/kwWc0lhf' },
      },
    }
    -- plugin/rssfeed.lua defines this command (and a <leader>rss map) on top of the telescope
    -- picker; redefining it here keeps `:RSSFeed` working without telescope.
    vim.api.nvim_create_user_command('RSSFeed', select_feed, { desc = 'Pick an RSS feed to read' })
  end,
  keys = {
    { '<leader>rss', select_feed, desc = 'RSS Feed' },
  },
}
