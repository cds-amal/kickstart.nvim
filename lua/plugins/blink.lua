return { -- Autocompletion
  'saghen/blink.cmp',
  event = 'VimEnter',
  version = '1.*',
  dependencies = {
    -- Snippet Engine
    {
      'L3MON4D3/LuaSnip',
      version = '2.*',
      build = (function()
        -- jsregexp gives snippets regex transforms; the build needs make.
        if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
          return
        end
        return 'make install_jsregexp'
      end)(),
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
      -- Mirrors built-in ins-completion: <C-y> accepts, <C-n>/<C-p> move,
      -- <C-space> opens the menu or docs, <C-e> hides, <Tab>/<S-Tab> jump
      -- snippet fields. See :h blink-cmp-config-keymap.
      preset = 'default',
      -- Give <C-k> back to Vim for digraph entry (:h i_CTRL-K). The preset's
      -- 'show_signature' always succeeds while signature.enabled is on, so
      -- its 'fallback' never reaches the built-in. <C-s> (lsp.lua) already
      -- opens signature help on demand, and blink auto-shows it in arguments.
      ['<C-k>'] = {},
    },

    appearance = { nerd_font_variant = 'mono' },

    completion = {
      -- Docs on demand via <C-space>; no automatic popup.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lsp', 'path', 'buffer', 'snippets', 'lazydev' },
      providers = {
        lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
      },
    },

    snippets = { preset = 'luasnip' },

    -- The Lua matcher; 'prefer_rust_with_warning' would download the
    -- prebuilt rust one instead (:h blink-cmp-config-fuzzy).
    fuzzy = { implementation = 'lua' },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  },
}
