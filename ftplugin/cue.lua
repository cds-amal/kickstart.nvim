-- ftplugin/cue.lua
-- Cue-specific buffer settings and commands.

vim.opt_local.makeprg = 'cue vet -c'
vim.opt_local.errorformat = '%f:%l:%c'

vim.api.nvim_buf_create_user_command(0, 'CueVet', function()
  vim.cmd 'make'
  vim.cmd 'copen'
end, { desc = 'Run cue vet and open the quickfix' })
