-- Local plugin: extracted to ~/dev/nvim-plugins/truth-table.nvim.
-- Loaded eagerly: its insert-mode abbreviations (and@ -> ∧ and friends) are
-- global, so lazy-loading on the commands would leave them unregistered until
-- the first :TruthTable. The plugin's setup() defines commands and mappings.
return {
  -- dir = '~/dev/nvim-plugins/truth-table.nvim',
  'cds-io/truth-table.nvim',
  lazy = false,
  config = function()
    -- Accept ≠ as a spelling of xor, the counterpart of the plugin's built-in
    -- = for iff. The plugin has no alias option, so substitute ahead of its
    -- tokenizer. ≠ and ⊕ are both three UTF-8 bytes, which keeps the byte
    -- positions in parse diagnostics accurate. core.tokenize captured the
    -- original function at load, so it is re-pointed as well.
    local predicate = require 'truth-table.predicate'
    local tokenize = predicate.tokenize
    predicate.tokenize = function(input)
      return tokenize((input:gsub('≠', '⊕')))
    end
    require('truth-table.core').tokenize = predicate.tokenize
  end,
}
