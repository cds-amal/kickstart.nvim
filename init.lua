-- selene: allow(mixed_table)
--[[

    - :help lua-guide

--]]

-- Leader keys must be set before lazy.nvim loads plugins.
vim.g.mapleader = ','
vim.g.maplocalleader = '\\'

-- Editor options (lives in lua/options.lua)
require 'options'

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require 'filetypes'

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
require('lazy').setup({
  -- Auto-import every spec in lua/plugins/ (see `:help lazy.nvim-🔌-plugin-spec`).
  { import = 'plugins' },
}, {
  -- The plugin family's house library, cds-lua, is a dependency the plugins
  -- pin in their own lazy.lua; with its checkout beside theirs it loads from
  -- there, and from GitHub on a machine without one.
  dev = {
    path = '~/dev/nvim-plugins',
    patterns = { 'cds-io/cds-lua' },
    fallback = true,
  },
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

require 'abbreviations'
require 'git-commit'
require 'messages'
require 'rs-commentary'
require 'keymaps'
require 'close-unnamed'
require 'strip-whitespaces'
require 'virtual-copy'

_G.dd = function(...)
  require('snacks').debug.inspect(...)
end
_G.bt = function()
  require('snacks').debug.backtrace()
end
vim.print = _G.dd
-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
