return {
  'LionyxML/gitlineage.nvim',
  dependencies = {
    'sindrets/diffview.nvim',
  },
  config = function()
    require('gitlineage').setup {
      keys = {
        next_commit = ']h',
        prev_commit = '[h',
      },
    }
  end,
}
