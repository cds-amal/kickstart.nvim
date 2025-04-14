-- selene:allow(mixed_table)
local M = {}

-- Define your plugins with named keys for organization
M.lazygit = {
  'kdheepak/lazygit.nvim',
  lazy = true,
  cmd = {
    'LazyGit',
    'LazyGitConfig',
    'LazyGitCurrentFile',
    'LazyGitFilter',
    'LazyGitFilterCurrentFile',
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  keys = {
    { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
  },
}

M.git_blame = {
  'f-person/git-blame.nvim',
  event = 'VeryLazy',
  opts = {
    enabled = true,
    message_template = ' <summary> • <date> • <author> • <<sha>>',
    date_format = '%m-%d-%Y %H:%M:%S',
    virtual_text_column = 1,
  },
  keys = {
    { '<leader>gt', '<cmd>GitBlameToggle<cr>', desc = 'it [T]oggle Blame' },
  },
}

-- Convert map to an array for lazy.nvim
return {
  M.lazygit,
  M.git_blame,
}
