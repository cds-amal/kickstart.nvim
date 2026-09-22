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

-- Every Unicode keymap starts with a backslash, so after `\` Neovim waits
-- 'timeoutlen' (300ms here) for the rest; type `\E` any slower and the
-- backslash lands literally. Abbreviations expand on the character typed
-- after the word instead of on a timer, so they back up the keymaps for the
-- `\word` operators: fast typing hits the keymap, slow typing the
-- abbreviation. They need `\` in 'iskeyword' to be legal (`\in` is neither
-- full-id nor end-id otherwise), which also makes `w` and `*` treat `\in` as
-- one word, a fair reading of TLA+. The symbolic operators (`/\`, `\/`, `<<`)
-- stay keymap-only: as "non-id" abbreviations they expand only on <C-]>.
vim.opt_local.iskeyword:append [[\]]

local function backslash_words()
  local plugin = require('lazy.core.config').plugins['tlaplus-nvim-plugin']
  local words, seen = {}, {}
  for _, line in ipairs(vim.fn.readfile(plugin.dir .. '/plugin/tla-unicode.csv')) do
    local _, ascii, unicode = unpack(vim.split(line, ','))
    for _, variant in ipairs(vim.split(ascii or '', ';')) do
      if variant:match '^\\%a+$' and not seen[variant] then
        seen[variant] = true
        table.insert(words, { variant, unicode })
      end
    end
  end
  return words
end

-- tlaplus-nvim-plugin tracks its state in b:tlaplus_mappings_defined.
map('<leader>tm', function()
  if vim.b.tlaplus_mappings_defined then
    vim.cmd 'TlaMappingsRemove'
    for _, word in ipairs(backslash_words()) do
      vim.keymap.del('ia', word[1], { buffer = true })
    end
    vim.notify 'TLA+ Unicode mappings off'
  else
    vim.cmd 'TlaMappingsAdd'
    for _, word in ipairs(backslash_words()) do
      vim.keymap.set('ia', word[1], word[2], { buffer = true, desc = 'TLA+ ' .. word[2] })
    end
    vim.notify 'TLA+ Unicode mappings on'
  end
end, 'TLA+: toggle Unicode input mappings')
