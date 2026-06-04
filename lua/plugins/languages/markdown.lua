-- selene:allow(mixed_table)

return {
  {
    'selimacerbas/markdown-preview.nvim',
    dependencies = { 'selimacerbas/live-server.nvim' },
    cmd = { 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    config = function()
      require('markdown_preview').setup {
        open_browser = true,
        mermaid_renderer = 'rust',
        -- We routinely run several Neovim instances. The default 'takeover'
        -- mode shares one browser tab across all of them: the first instance
        -- owns the server and opens the tab, every other instance silently
        -- becomes a secondary that pushes content into that tab without
        -- popping a browser, so ,mp looks dead. 'multi' gives each instance
        -- its own server + tab; port = 0 lets the OS pick a free port.
        instance_mode = 'multi',
        port = 0,
      }
      vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreview<cr>', { desc = 'Markdown Preview Start' })
      vim.keymap.set('n', '<leader>ms', '<cmd>MarkdownPreviewStop<cr>', { desc = 'Markdown Preview Stop' })
    end,
  },
}
