-- ftplugin/zsh.lua
-- ZSH-specific configuration and functionality

-- Set buffer-local options
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 0
vim.opt_local.expandtab = true
vim.opt_local.foldlevel = 3

-- Load the ZSH command utilities module
local zsh_utils = require('custom.plugins.languages.zsh-utils')

-- Create buffer-local mappings
vim.keymap.set('n', '<localleader>s', function()
  zsh_utils.split_at_dashes(false)
end, { buffer = true, silent = true, desc = 'Split at dashes' })

vim.keymap.set('n', '<localleader>sq', function()
  zsh_utils.split_at_dashes(true)
end, { buffer = true, silent = true, desc = 'Split at dashes (confirm)' })

vim.keymap.set('n', '<leader>tj', zsh_utils.toggle_split_join, {
  buffer = true,
  desc = 'Toggle split/join for zsh commands'
})

-- Create user commands
vim.api.nvim_buf_create_user_command(0, 'Split', function()
  zsh_utils.split_command_simple()
end, { desc = 'Split command at dashes' })

vim.api.nvim_buf_create_user_command(0, 'Splitq', function()
  zsh_utils.split_command_simple(true)
end, { desc = 'Split command at dashes (confirm)' })