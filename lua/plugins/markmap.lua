-- Markmap: Visualize markdown as mindmaps
return {
  'Zeioth/markmap.nvim',
  build = 'yarn global add markmap-cli',
  cmd = { 'MarkmapOpen', 'MarkmapSave', 'MarkmapWatch', 'MarkmapWatchStop' },
  opts = {
    html_output = '/tmp/markmap.html', -- Temp location for generated HTML
    hide_toolbar = false, -- Show toolbar with zoom/expand controls
    grace_period = 3600000, -- 1 hour in milliseconds
  },
  config = function(_, opts)
    require('markmap').setup(opts)
  end,
  keys = {
    -- Open current markdown file as mindmap
    { '<localleader>M', '<cmd>MarkmapOpen<cr>', desc = 'Zettel: Open mindmap', ft = 'markdown' },

    -- Save mindmap to file
    { '<localleader>S', '<cmd>MarkmapSave<cr>', desc = 'Zettel: Save mindmap', ft = 'markdown' },

    -- Watch mode - auto-refresh mindmap on save
    { '<localleader>W', '<cmd>MarkmapWatch<cr>', desc = 'Zettel: Watch mindmap', ft = 'markdown' },
  },
}
