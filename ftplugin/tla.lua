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
-- backslash lands literally. The same goes for `=`: `==`, `=>` and `=|` all
-- start with it. Abbreviations expand on the character typed after the word
-- instead of on a timer, so they back up the keymaps for the `\word`
-- operators and for `==`: fast typing hits the keymap, slow typing the
-- abbreviation. An abbreviation ending in a non-keyword character (a
-- "non-id" one, which `==` is unless `=` is in 'iskeyword') expands only on
-- <Esc>, <CR> and <C-]>, whatever :help abbreviations says about space; one
-- made entirely of keyword characters expands on the space too. So `\` and
-- `=` join 'iskeyword', which also makes `w` and `*` treat `\in` and `x=1`
-- as one word, a fair reading of TLA+. The remaining symbolic operators
-- (`/\`, `\/`, `<<`) stay keymap-only rather than pull `/` and `<` into
-- 'iskeyword' too.
vim.opt_local.iskeyword:append { [[\]], '=' }

local function abbreviated_words()
  local plugin = require('lazy.core.config').plugins['tlaplus-nvim-plugin']
  local words, seen = {}, {}
  for _, line in ipairs(vim.fn.readfile(plugin.dir .. '/plugin/tla-unicode.csv')) do
    local _, ascii, unicode = unpack(vim.split(line, ','))
    for _, variant in ipairs(vim.split(ascii or '', ';')) do
      if (variant:match '^\\%a+$' or variant == '==') and not seen[variant] then
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
    for _, word in ipairs(abbreviated_words()) do
      vim.keymap.del('ia', word[1], { buffer = true })
    end
    vim.notify 'TLA+ Unicode mappings off'
  else
    vim.cmd 'TlaMappingsAdd'
    for _, word in ipairs(abbreviated_words()) do
      vim.keymap.set('ia', word[1], word[2], { buffer = true, desc = 'TLA+ ' .. word[2] })
    end
    vim.notify 'TLA+ Unicode mappings on'
  end
end, 'TLA+: toggle Unicode input mappings')
