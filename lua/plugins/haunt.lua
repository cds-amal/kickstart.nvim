-- haunt.nvim: Ghost text bookmarks with annotations
-- Annotate lines with virtual text without modifying files
return {
  'TheNoeTrevino/haunt.nvim',
  event = 'VeryLazy',
  opts = {
    sign = '󱙝',
    sign_hl = 'DiagnosticInfo',
    virt_text_hl = 'HauntAnnotation',
    annotation_prefix = ' 󰆉 ',
    virt_text_pos = 'eol',
    -- data_dir = nil, -- defaults to stdpath('data')/haunt
  },
  keys = {
    { '<leader>ha', function() require('haunt.api').annotate() end, desc = 'Haunt: Annotate line' },
    { '<leader>hd', function() require('haunt.api').delete() end, desc = 'Haunt: Delete annotation' },
    { '<leader>ht', function() require('haunt.api').toggle_annotation() end, desc = 'Haunt: Toggle annotation' },
    { '<leader>hT', function() require('haunt.api').toggle_all_lines() end, desc = 'Haunt: Toggle all annotations' },
    { '<leader>hc', function() require('haunt.api').clear_all() end, desc = 'Haunt: Clear all annotations' },
    { '<leader>hq', function() require('haunt.api').to_quickfix() end, desc = 'Haunt: Send to quickfix' },
    { '<leader>hl', function() require('haunt.picker').show() end, desc = 'Haunt: List annotations (picker)' },
    -- Navigation with ]H / [H (uppercase to avoid collision with gitlineage's ]h/[h)
    { ']H', function() require('haunt.api').next() end, desc = 'Next haunt annotation' },
    { '[H', function() require('haunt.api').prev() end, desc = 'Previous haunt annotation' },
  },
}
