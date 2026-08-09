-- Staged/unstaged diff browser. The file panel splits changes into
-- Staged (index vs HEAD) and Unstaged (worktree vs index) sections;
-- selecting an entry opens the matching side-by-side diff.
return {
  -- Maintained fork of sindrets/diffview.nvim (upstream quiet since 2024);
  -- same commands and lua module names.
  'dlyongemallo/diffview-plus.nvim',
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory', 'DiffviewToggleFiles', 'DiffviewFocusFiles' },
  keys = {
    {
      '<leader>hv',
      function()
        if require('diffview.lib').get_current_view() then
          vim.cmd 'DiffviewClose'
        else
          vim.cmd 'DiffviewOpen'
        end
      end,
      desc = 'git diff[v]iew toggle',
    },
    { '<leader>hH', '<cmd>DiffviewFileHistory %<cr>', desc = 'git file [H]istory' },
  },
}
