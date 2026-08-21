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
  'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically

  { -- Pending-keybind hints
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      -- this setting is independent of vim.o.timeoutlen
      delay = 0,
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },

        -- Disambiguate vim's text-search g-keys from the LSP grX family.
        -- The defaults that ship with which-key say "Goto local/global
        -- declaration", which sounds LSP-ish; in reality these are pre-LSP
        -- regex searches over the buffer text. Real go-to-definition lives
        -- in grd / grD / grt (set buffer-locally in lua/lsp.lua on_attach).
        { 'gd', desc = 'Goto local decl (vim regex; LSP is grd)' },
        { 'gD', desc = 'Goto global decl (vim regex; LSP is grD)' },
      },
    },
  },

  -- Fuzzy finder keymaps live in lua/keymaps.lua; all pickers are driven
  -- by Snacks.picker (see lua/plugins/snacks.lua).

  -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  { -- Main LSP configuration; implementation in lua/lsp.lua
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'b0o/schemastore.nvim',
      'saghen/blink.cmp',
    },
    config = function()
      require('lsp').setup()
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>F',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { rust = true, c = true, cpp = true, javascript = true, typescript = true, javascriptreact = true, typescriptreact = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },

  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        config = function()
          local ls = require 'luasnip'
          -- Re-evaluate function/dynamic nodes on every keystroke, not just
          -- InsertLeave (the default). The `impl` snippet depends on this: its
          -- body watches the trait name and must swap in the fmt skeleton the
          -- moment you finish typing `Display`, while still in insert mode.
          ls.setup { update_events = { 'TextChanged', 'TextChangedI' } }
          -- Load custom Lua snippets after LuaSnip is initialized
          vim.schedule(function()
            require('luasnip.loaders.from_lua').lazy_load { paths = '~/.config/nvim/lua/snippets' }
          end)

          -- Cycle choice nodes. blink owns <Tab>/<S-Tab> for jumping, so these
          -- only move *between choices* on the active choiceNode (used by the
          -- recursive `errc` snippet to spawn the next variant/msg pair).
          -- <C-h/j/k/l> are taken by herdr/tmux navigation; <C-f>/<C-b> are free in
          -- insert and select mode.
          vim.keymap.set({ 'i', 's' }, '<C-f>', function()
            if ls.choice_active() then
              ls.change_choice(1)
            end
          end, { desc = 'LuaSnip: next choice' })
          vim.keymap.set({ 'i', 's' }, '<C-b>', function()
            if ls.choice_active() then
              ls.change_choice(-1)
            end
          end, { desc = 'LuaSnip: previous choice' })
        end,
      },
      'folke/lazydev.nvim',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        --   <c-y> to accept ([y]es) the completion.
        --    This will auto-import if your LSP supports it.
        --    This will expand snippets if the LSP sent a snippet.
        -- 'super-tab' for tab to accept
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- For an understanding of why the 'default' preset is recommended,
        -- you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        --
        -- All presets have the following mappings:
        -- <tab>/<s-tab>: move to right/left of your snippet expansion
        -- <c-space>: Open menu or open docs if already open
        -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
        -- <c-e>: Hide menu
        -- <c-k>: Toggle signature help
        --
        -- See :h blink-cmp-config-keymap for defining your own keymap
        preset = 'default',

        -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
        --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'buffer', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See :h blink-cmp-config-fuzzy for more information
      fuzzy = { implementation = 'lua' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },

  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, use `:colorscheme <Tab>` or `Snacks.picker.colorschemes()`.
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    dependencies = 'p00f/alabaster.nvim',
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        styles = {
          comments = { italic = false }, -- Disable italics in comments
        },
      }

      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'tokyonight-night'
      -- Increase comment contrast: brighter and bold
      -- vim.api.nvim_set_hl(0, 'Comment', { fg = '#7aa2f7', bold = true })
      -- vim.api.nvim_set_hl(0, 'Comment', { fg = '#7aa2f7' })
    end,
  },

  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

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
      require('nvim-treesitter').install { 'bash', 'c', 'cue', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'rust', 'vim', 'vimdoc' }

      -- Use treesitter's AST-aware indentexpr wherever a parser AND indent
      -- queries are both available. Without the queries check, a parser with
      -- no indents.scm makes indentexpr return 0, sending <CR> to column 0.
      -- Threshold-to-change: filetype is used as a proxy for the parser language;
      -- this is correct only while we register at most one alias (bash<-zsh).
      -- If more language aliases get registered, resolve the parser language
      -- properly (e.g. via vim.treesitter.language.get_lang) instead.
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('ts-indent', { clear = true }),
        callback = function(args)
          if pcall(vim.treesitter.get_parser, args.buf) and vim.treesitter.query.get(vim.bo[args.buf].filetype, 'indents') then
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
