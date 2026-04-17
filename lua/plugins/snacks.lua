return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    debug = { enabled = true },
    explorer = { enabled = true },
    gh = { enabled = true },
    gitbrowse = { enabled = true },
    indent = { enabled = true },
    picker = { enabled = true },
    input = { enabled = true },
    notify = { enabled = true },
    rename = { enabled = true },
    scope = { enabled = true },
    words = { enabled = true, modes = { 'n' } },
  },
  keys = {
    {
      '\\\\',
      function()
        require('snacks').explorer()
      end,
      desc = 'Toggle file explorer',
    },
    {
      '<leader>bd',
      function()
        require('snacks').bufdelete()
      end,
      desc = 'Delete Buffer',
    },
    {
      'gb',
      function()
        Snacks.picker.buffers()
      end,
      desc = '[G]et [B]uffers',
    },
    {
      '<leader>cR',
      function()
        require('snacks').rename.rename_file()
      end,
      desc = 'Rename File',
    },
    {
      '<leader>gB',
      function()
        require('snacks').gitbrowse()
      end,
      desc = 'Git Browse',
      mode = { 'n', 'v' },
    },
    {
      '<leader>gi',
      function()
        Snacks.picker.gh_issue()
      end,
      desc = 'GitHub Issues (open)',
    },
    {
      '<leader>gI',
      function()
        Snacks.picker.gh_issue { state = 'all' }
      end,
      desc = 'GitHub Issues (all)',
    },
    {
      '<leader>gp',
      function()
        Snacks.picker.gh_pr()
      end,
      desc = 'GitHub Pull Requests (open)',
    },
    {
      '<leader>gP',
      function()
        Snacks.picker.gh_pr { state = 'all' }
      end,
      desc = 'GitHub Pull Requests (all)',
    },
    {
      ']w',
      function()
        Snacks.words.jump(1, true)
      end,
      desc = 'Next LSP reference',
    },
    {
      '[w',
      function()
        Snacks.words.jump(-1, true)
      end,
      desc = 'Previous LSP reference',
    },
    {
      '<leader>n',
      function()
        require('snacks').notifier.show_history()
      end,
      desc = 'Notification History',
    },
  },
}
