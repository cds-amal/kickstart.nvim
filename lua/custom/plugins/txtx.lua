-- lua/custom/plugins/txtx.lua
return {
  -- Local plugin specification
  dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins/txtx',

  config = function()
    require('custom.plugins.txtx.txtx').setup {
      -- Optional custom keymaps
      keymaps = {
        list_runbooks = '<leader>rr', -- List all runbooks
        list_alternates = '<leader>ra', -- List alternate files for current runbook
        next_alternate = '<leader>rn', -- Go to next alternate file
        prev_alternate = '<leader>rp', -- Go to previous alternate file
      },
      -- Files to scan for runbooks entry
      runbook_files = { 'runbooks.yml', 'runbooks.yaml' },
      -- Extension for runbook files
      tx_extension = '.tx',
    }
  end,
}
