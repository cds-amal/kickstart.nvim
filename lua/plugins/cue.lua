-- selene: allow(mixed_table)

return {
  dir = vim.fn.stdpath 'config' .. '/lua/cue_local',
  name = 'cue_local',
  ft = 'cue',
  config = function()
    require('cue_local').setup()
  end,
}
