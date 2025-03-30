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
    dashboard = { enabled = true },
    debug = { enabled = true },
    explorer = { enabled = true },
    gitbrowse = { enabled = true },
    input = { enabled = true },
    notify = { enabled = true },
    rename = { enabled = true },
  },
  keys = {
    {
      '<leader>bd',
      function()
        require('snacks').bufdelete()
      end,
      desc = 'Delete Buffer',
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
      '<leader>n',
      function()
        require('snacks').notifier.show_history()
      end,
      desc = 'Notification History',
    },
  },
}
