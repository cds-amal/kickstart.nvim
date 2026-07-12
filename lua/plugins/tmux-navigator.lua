-- <C-h/j/k/l> are owned by vim-herdr-navigation (editor/nvim.lua): move
-- between splits, and at an edge cross into the surrounding herdr pane. It
-- falls back to TmuxNavigate* under tmux and plain wincmd otherwise, so
-- vim-tmux-navigator stays installed but with its own mappings disabled —
-- single source of truth for the chord.
return {
  'christoomey/vim-tmux-navigator',
  lazy = false,
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  config = function()
    dofile(vim.fn.expand '~/.config/herdr/plugins/vim-herdr-navigation/editor/nvim.lua')
  end,
  keys = {
    { '<c-\\>', '<cmd>TmuxNavigatePrevious<cr>', desc = 'Navigate to previous pane (tmux)' },
  },
}
