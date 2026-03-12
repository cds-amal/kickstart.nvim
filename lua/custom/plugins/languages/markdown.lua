-- selene:allow(mixed_table)

return {
  'selimacerbas/markdown-preview.nvim',
  dependencies = { 'selimacerbas/live-server.nvim' },
  cmd = { 'MarkdownPreview', 'MarkdownPreviewStop' },
  ft = { 'markdown' },
  config = function()
    require('markdown_preview').setup {
      open_browser = true,
      mermaid_renderer = 'rust',
    }
  end,
  keys = {
    { '<leader>mp', '<cmd>MarkdownPreview<cr>', desc = 'Markdown Preview Start', ft = 'markdown' },
    { '<leader>ms', '<cmd>MarkdownPreviewStop<cr>', desc = 'Markdown Preview Stop', ft = 'markdown' },
  },
}
