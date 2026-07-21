-- Two specs in one file: the framework (which carries the kata config and
-- the global `:Katas` keymap) and the course plugin (which just needs to
-- be on rtp so `require('katas.solana_rust')` resolves at activation time).
return {
  -- 1) Framework. opts.katas is the source of truth for what courses
  --    exist; lazy passes opts to require('kata').setup(opts).
  {
    'cds-io/kata-framework',
    dir = '~/nvim-plugins/kata-framework',
    opts = {
      katas = {
        solana_rust = '~/dev/solana-rust-vscode-course',
      },
    },
    keys = {
      { '<leader>sk', '<cmd>Katas<CR>', desc = '[S]olana [K]atas: pick course' },
    },
  },

  -- 2) Course plugin: pure provider module sitting on rtp. No setup, no
  --    triggers; lazy will eager-load it (no triggers means no laziness)
  --    so the directory is on rtp by the time :Katas dispatches.
  {
    dir = '~/dev/solana-rust-vscode-course/neovim',
    dependencies = {
      'cds-io/kata-framework',
    },
  },
}
