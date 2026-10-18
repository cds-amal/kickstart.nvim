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
  'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically

  -- Fuzzy finder keymaps live in lua/keymaps.lua; all pickers are driven
  -- by Snacks.picker (see lua/plugins/snacks.lua).

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup {
        -- Linewise adds (V sa, or a linewise motion like sa_ / sa2j) place
        -- each delimiter on its own line and indent the wrapped lines;
        -- charwise adds stay inline. Prefer `}` over `{` for linewise braces:
        -- the `{` builtin pads with inner spaces, which linewise placement
        -- turns into a trailing space after the brace.
        respect_selection_type = true,
        custom_surroundings = {

          -- - saiw c - surround inner word with console code fence
          -- - sa2j c - surround current line and next line with console code fence
          -- - In visual mode: select your text, then sa c
          ['c'] = {
            output = { left = '```console\n', right = '\n```' },
          },
          ['r'] = {
            output = { left = '```rust\n', right = '\n```' },
          },
          ['C'] = {
            output = { left = '/*\n', right = '\n*/' },
          },

          -- - V sa l (or sa_ l) - wrap line(s) in an indented `loop { }` block
          ['l'] = {
            output = { left = 'loop {', right = '}' },
          },
        },
      }

      -- The fence surrounds above embed `\n` in their output, which only
      -- works through the charwise insert path: the linewise branch that
      -- respect_selection_type enables feeds the string to `append()`, where
      -- the `\n` becomes a literal NUL, and the fenced lines pick up an
      -- indent level they shouldn't have. Keep the old behavior in markdown,
      -- where the fences live.
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        callback = function()
          vim.b.minisurround_config = { respect_selection_type = false }
        end,
        desc = 'Inline surround adds in markdown (fence surrounds embed \\n)',
      })

      -- Disable mini.operators' `replace` operator: its default `gr` prefix
      -- collides with Neovim 0.11+'s reserved LSP namespace (grD, grr, gri,
      -- gra, grn, ...). Keeping the other operators on their defaults.
      require('mini.operators').setup { replace = { prefix = '' } }

      -- Auto-pair brackets/quotes (replaces nvim-autopairs)
      require('mini.pairs').setup()

      -- mini.pairs maps <CR> without remapping, and a key that is not
      -- remapped skips abbreviation expansion, so `def@<CR>` would keep its
      -- `def@`. <C-]> is exempt from that rule: it expands a pending
      -- abbreviation and inserts nothing, so it goes in front.
      vim.keymap.set('i', '<CR>', function()
        return vim.keycode '<C-]>' .. require('mini.pairs').cr()
      end, { expr = true, replace_keycodes = false, desc = 'Expand abbreviation, then MiniPairs <CR>' })

      -- Don't autopair `'` in Rust buffers. mini.pairs' neigh_pattern guard
      -- (skip when preceded by a letter) handles English contractions, but a
      -- lifetime `'a` is preceded by `<`, `&`, `,`, etc., so it slips through
      -- and you get `<'info'>`. `'` is a global mapping, so the documented way
      -- to revert it for a buffer is to shadow it with a buffer-local mapping
      -- that just inserts the literal quote. (Costs nothing: the `closeopen`
      -- autopair saved no keystrokes for char literals anyway.)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'rust',
        desc = "Disable mini.pairs ' autopairing for Rust lifetimes",
        callback = function(args)
          vim.keymap.set('i', "'", "'", { buffer = args.buf })
        end,
      })

      require('mini.comment').setup {
        options = {
          custom_commentstring = function(ref_position)
            -- Get current buffer's filetype
            local ft = vim.bo.filetype

            -- For Cue files, use the appropriate comment string
            if ft == 'cue' or ft == 'hcl' then
              return '// %s'
            end

            -- For embedded Cue code in other files, check the tree-sitter context
            if vim.fn.has 'nvim-0.9' == 1 then
              local has_parser, parser = pcall(vim.treesitter.get_parser, 0)
              if has_parser and parser then
                -- Check if we're in Cue language context at the reference position
                local row, col = ref_position[1] - 1, ref_position[2] - 1
                local lang_tree = parser:language_for_range { row, col, row, col + 1 }
                if lang_tree and lang_tree:lang() == 'cue' then
                  return '// %s'
                end
              end
            end

            -- For other cases, use the default detection
            return nil
          end,
        },
      }

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        -- The plugins' runs out (`⟳ roots surfpool 14s`, `⟳ events google 2s`) ahead of
        -- the cursor position while a projection, the roots list, a calendar page or a
        -- create is being waited on; each plugin redraws the statusline once a second
        -- while anything of its own is out.
        local has_crosscut, crosscut = pcall(require, 'crosscut')
        local has_calplus, calplus = pcall(require, 'calplus')
        local segments = {}
        for _, segment in ipairs { has_crosscut and crosscut.activity() or '', has_calplus and calplus.activity() or '' } do
          if segment ~= '' then
            segments[#segments + 1] = segment
          end
        end
        local activity = table.concat(segments, ' · ')
        if activity ~= '' then
          return activity:gsub('%%', '%%%%') .. '  %2l:%-2v'
        end
        return '%2l:%-2v'
      end

      -- Setup mini.splitjoin with its configuration
      require('mini.splitjoin').setup {
        -- Default configuration
        mappings = {
          toggle = '', -- Disable default toggle to use our custom one
          split = 'gS',
          join = 'gJ',
        },
      }
      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
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
