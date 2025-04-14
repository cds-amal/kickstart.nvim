-- selene: allow(mixed_table)

return {
  'greggh/claude-code.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim', -- Required for git operations
  },
  config = function()
    require('claude-code').setup {
      command = '~/.claude/local/claude',
    }
  end,
}
