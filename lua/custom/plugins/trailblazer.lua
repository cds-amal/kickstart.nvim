return {
  'LeonHeidelbach/trailblazer.nvim',
  config = function()
    require('trailblazer').setup {
      -- Enable auto save and load
      auto_save_trailblazer_state_on_exit = true,
      auto_load_trailblazer_state_on_enter = true,

      -- Your existing mappings
      mappings = {
        nv = {
          motions = {
            new_trail_mark = '<A-l>',
            track_back = '<A-j>',
            toggle_trail_mark_list = '<A-m>',
          },
          actions = {
            delete_all_trail_marks = '<A-D>',
            set_trail_mark_select_mode = '<A-t>',
            switch_to_next_trail_mark_stack = '<A-.>',
            switch_to_previous_trail_mark_stack = '<A-,>',
          },
        },
        i = {
          motions = {
            new_trail_mark = '<C-l>',
          },
        },
      },
    }

    -- Initialize the runtime flag by saving a session after plugin setup
    vim.defer_fn(function()
      -- Create at least one trail mark first (optional)
      -- vim.cmd("TrailBlazerNewTrailMark")

      -- Then save the session to set the runtime flag
      vim.cmd 'TrailBlazerSaveSession'
    end, 1000) -- Wait 1 second after startup to ensure plugin is fully loaded
  end,
}
