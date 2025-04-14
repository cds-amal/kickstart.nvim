-- lazy.nvim
return {
  'chrisgrieser/nvim-origami',
  event = 'VeryLazy',
  opts = {
    autoFold = {
      enabled = true,
    },
    -- across sessions needs ufo
    -- keepFoldsAcrossSessions = true,
  },

  init = function()
    vim.opt.foldlevel = 99
    vim.opt.foldlevelstart = 99
  end,
}
