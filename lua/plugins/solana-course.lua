return {
  dir = '~/dev/solana-rust-vscode-course/neovim',
  name = 'katas.solana_rust',
  main = 'katas.solana_rust',
  dependencies = {
    { 'cds-io/kata-framework', dir = '~/nvim-plugins/kata-framework' },
    'MeanderingProgrammer/render-markdown.nvim',
  },
  cmd = { 'CourseOpen', 'CourseBuild' },
  keys = {
    { '<leader>sc', '<cmd>CourseOpen<CR>', desc = '[S]olana [C]ourse: open exercise picker' },
  },
  opts = {
    runner = 'cargo',
    keymap = false,
  },
}
