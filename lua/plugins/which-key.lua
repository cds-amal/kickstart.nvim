return { -- Pending-keybind hints
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    -- delay between pressing a key and opening which-key (milliseconds)
    -- this setting is independent of vim.o.timeoutlen
    delay = 0,
    -- List a popup in the order its keys were registered with which-key
    -- ("manual"), so a plugin that registers its keys by family shows up
    -- grouped. This is the default list with "manual" added.
    sort = { 'local', 'order', 'group', 'manual', 'alphanum', 'mod' },
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
}
