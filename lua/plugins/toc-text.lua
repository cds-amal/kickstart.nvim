-- Local plugin: extracted to ~/dev/nvim-plugins/toc-text.nvim.
-- Eager-load (no triggers): the inline TOC extmark refresh runs from
-- BufReadPost/BufEnter/BufWinEnter autocmds, so it must be active from startup.
return {
  dir = '~/dev/nvim-plugins/toc-text.nvim',
}
