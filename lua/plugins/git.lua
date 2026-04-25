return {
  {
    'akinsho/git-conflict.nvim',
    version = '*',
    event = 'BufReadPre',
    opts = {
      default_mappings = true,
      disable_diagnostics = false,
    },
  },
}
