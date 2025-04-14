-- Additional keymaps for Zettelkasten workflow
-- (obsidian.nvim keymaps are in obsidian.lua)
return {
  'folke/which-key.nvim',
  optional = true,
  opts = function(_, opts)
    -- Add Zettelkasten submenu to which-key
    opts.spec = opts.spec or {}
    table.insert(opts.spec, {
      { '<leader>t', group = 'zettel-todos', icon = '✓' },
    })
  end,
  keys = {
    -- Todo aggregation keymaps using <leader>t prefix (separate from localleader)
    {
      '<leader>tt',
      function()
        require('custom.zettel-todos').find_todos()
      end,
      desc = 'Zettel: Find incomplete TODOs',
    },

    {
      '<leader>tc',
      function()
        require('custom.zettel-todos').find_completed()
      end,
      desc = 'Zettel: Find completed TODOs',
    },

    {
      '<leader>ta',
      function()
        require('custom.zettel-todos').find_all_tasks()
      end,
      desc = 'Zettel: Find all tasks',
    },

    {
      '<leader>tT',
      function()
        require('custom.zettel-todos').find_tagged_todos()
      end,
      desc = 'Zettel: Find tagged TODOs',
    },

    {
      '<leader>tq',
      function()
        require('custom.zettel-todos').todos_to_quickfix()
      end,
      desc = 'Zettel: TODOs to quickfix',
    },
  },
}
