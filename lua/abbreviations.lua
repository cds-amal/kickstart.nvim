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
