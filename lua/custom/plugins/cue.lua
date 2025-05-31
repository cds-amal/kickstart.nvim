-- selene: allow(mixed_table)

return {
  dir = vim.fn.stdpath 'config' .. '/lua/custom/cue_local',
  name = 'cue_local',
  ft = 'cue',
  config = function()
    require('custom.cue_local').setup()
  end,
}
