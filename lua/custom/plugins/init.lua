-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

return {
  -- Load custome plugins
  require 'custom.plugins.treesitter.treesitter',
  require 'custom.plugins.languages',
  require 'custom.plugins.git.git',
  -- require 'custom.plugins.jq-treesitter',
}
