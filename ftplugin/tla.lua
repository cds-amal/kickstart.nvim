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

-- tlaplus-nvim-plugin tracks its state in b:tlaplus_mappings_defined.
map('<leader>tm', function()
  if vim.b.tlaplus_mappings_defined then
    vim.cmd 'TlaMappingsRemove'
    vim.notify 'TLA+ Unicode mappings off'
  else
    vim.cmd 'TlaMappingsAdd'
    vim.notify 'TLA+ Unicode mappings on'
  end
end, 'TLA+: toggle Unicode input mappings')
