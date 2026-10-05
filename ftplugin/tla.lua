-- ftplugin/tla.lua
-- TLA+ buffer settings and keymaps.

-- Neovim ships no syntax/tla.vim, so treesitter is the only highlighter.
vim.treesitter.start()

vim.opt_local.commentstring = [[\* %s]]

local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { buffer = true, desc = desc })
end

map('<localleader>c', '<Cmd>TlaCheck<CR>', 'TLA+: model check with TLC')
map('<localleader>t', '<Cmd>TlaTranslate<CR>', 'TLA+: translate PlusCal')

-- Unicode operators are typed on purpose, with the global `word@`
-- abbreviations (init.lua and truth-table.nvim): `in@` for ∈, `def@` for ≜.
-- ASCII operators stay as typed or pasted. With `@` in 'iskeyword' each
-- abbreviation is made entirely of keyword characters, so it also expands
-- straight after punctuation: `(not@<C-]>P` gives `(¬P`, where a trailing
-- non-keyword `@` needs whitespace in front. Straight after an identifier
-- nothing expands, which is why tuples keep their ASCII `<<x, y>>`.
vim.opt_local.iskeyword:append '@-@'

-- Spellings where TLA+ differs from the global set, or the set has none.
local abbreviations = {
  -- the global `implies@` is →, which TLA+ reads as `->`
  ['implies@'] = '⇒',
  ['always@'] = '□',
  ['eventually@'] = '◇',
}

for lhs, rhs in pairs(abbreviations) do
  vim.keymap.set('ia', lhs, rhs, { buffer = true, desc = 'TLA+ ' .. rhs })
end
