-- selene: allow(mixed_table)
--[[

    - :help lua-guide

--]]

-- Leader keys must be set before lazy.nvim loads plugins.
vim.g.mapleader = ','
vim.g.maplocalleader = '\\'

-- Editor options (lives in lua/options.lua)
require 'options'

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- NOTE: <C-hjkl> window navigation is handled by vim-herdr-navigation
-- (falls back to vim-tmux-navigator under tmux); see plugins/tmux-navigator.lua

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- MATH abbreviations. The logic ones (and@, or@, not@, ...) are registered by
-- truth-table.nvim; see :help truth-table-abbreviations.
local abbreviations = {
  -- Sets
  ['in@'] = '∈',
  ['notin@'] = '∉',
  ['subset@'] = '⊂',
  ['subseteq@'] = '⊆',
  ['union@'] = '∪',
  ['inter@'] = '∩',
  ['empty@'] = '∅',
  ['setminus@'] = '∖',

  -- Comparisons and definitions
  ['neq@'] = '≠',
  ['leq@'] = '≤',
  ['geq@'] = '≥',
  ['approx@'] = '≈',
  ['equiv@'] = '≡',
  ['def@'] = '≜',

  -- Arrows
  ['to@'] = '→',
  ['from@'] = '←',
  ['mapsto@'] = '↦',
  ['leadsto@'] = '↝',

  -- Number sets
  ['nat@'] = 'ℕ',
  ['int@'] = 'ℤ',
  ['rat@'] = 'ℚ',
  ['real@'] = 'ℝ',

  -- Arithmetic
  ['times@'] = '×',
  ['div@'] = '÷',
  ['pm@'] = '±',
  ['inf@'] = '∞',
}

for lhs, rhs in pairs(abbreviations) do
  vim.cmd.iabbrev { lhs, rhs }
end

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

-- Add TLA filetype
vim.filetype.add {
  extension = {
    tla = 'tla',
  },
}

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

  -- Fuzzy finder keymaps live in lua/keymaps.lua; all pickers are driven
  -- by Snacks.picker (see lua/plugins/snacks.lua).

  { -- Install and manage tree-sitter parsers (highlighting/indent are built into Neovim 0.12+)
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      vim.treesitter.language.register('bash', 'zsh')
      vim.treesitter.language.register('tlaplus', 'tla')
      require('nvim-treesitter').install {
        'bash',
        'c',
        'css',
        'cue',
        'diff',
        'html',
        'http',
        'javascript',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'rust',
        'svelte',
        'tlaplus',
        'typescript',
        'vim',
        'vimdoc',
      }

      -- Neovim only auto-starts treesitter highlighting for the filetypes
      -- whose bundled ftplugin does so (lua, help, markdown, query); the
      -- nvim-treesitter main branch never does it for you. Everything else
      -- here still looked highlighted only because a legacy syntax/*.vim
      -- ships in the runtime, which svelte lacks. Start the highlighter for
      -- any buffer that has an installed parser.
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('ts-highlight', { clear = true }),
        callback = function(args)
          if pcall(vim.treesitter.get_parser, args.buf) then
            pcall(vim.treesitter.start, args.buf)
          end
        end,
      })

      -- Use treesitter's AST-aware indentexpr wherever a parser AND indent
      -- queries are both available. Without the queries check, a parser with
      -- no indents.scm makes indentexpr return 0, sending <CR> to column 0.
      -- Queries are keyed by parser language, not filetype, so resolve
      -- through the alias table (zsh->bash, tla->tlaplus).
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('ts-indent', { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang and pcall(vim.treesitter.get_parser, args.buf) and vim.treesitter.query.get(lang, 'indents') then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- Auto-import every spec in lua/plugins/ (see `:help lazy.nvim-🔌-plugin-spec`).
  { import = 'plugins' },
}, {
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
