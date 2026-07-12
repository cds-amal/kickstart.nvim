-- Local plugin: extracted to ~/dev/nvim-plugins/truth-table.nvim.
-- Lazy-load on the commands and keymaps; the plugin's setup() defines the real
-- mappings (lazy feeds the key back after loading).
return {
  'cds-io/truth-table.nvim',
  cmd = {
    'TruthTable',
    'TruthTableExpand',
    'TruthTableToggle',
    'TruthTableDropRow',
    'TruthTableDropColumn',
  },
  keys = {
    { '<leader>ttn', desc = 'New truth table' },
    { '<leader>tte', desc = 'Expand truth table' },
    { '<leader>ttt', desc = 'Toggle 0/1 ↔ F/T' },
    { '<leader>ttr', desc = 'Drop truth table row' },
    { '<leader>ttc', desc = 'Drop truth table column' },
  },
}
