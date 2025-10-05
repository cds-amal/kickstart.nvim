-- selene:allow(mixed_table)

return {
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = 'cd app && yarn install',
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }

      -- Define the Vimscript function directly
      vim.cmd [[
        function! OpenMarkdownPreview(url)
          echom "URL received: " . a:url
          execute "silent ! open -a 'Zen Browser' -n --args --new-window " . a:url
        endfunction
]]

      vim.g.mkdp_browserfunc = 'OpenMarkdownPreview'
    end,
    ft = { 'markdown' },
  },
}
