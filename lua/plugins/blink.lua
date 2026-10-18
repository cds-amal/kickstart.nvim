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
      -- <c-k>: Toggle signature help (unbound below)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      preset = 'default',
      -- Give <C-k> back to Vim for digraph entry (:h i_CTRL-K). The preset's
      -- 'show_signature' always succeeds while signature.enabled is on, so
      -- its 'fallback' never reaches the built-in. <C-s> (lsp.lua) already
      -- opens signature help on demand, and blink auto-shows it in arguments.
      ['<C-k>'] = {},

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
}
