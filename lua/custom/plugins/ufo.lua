return {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },

  config = function()
    vim.o.foldcolumn = '1' -- '0' is not bad
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    local ufo = require 'ufo'
    -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
    vim.keymap.set('n', 'zR', ufo.openAllFolds, { desc = 'Reveal all folds' })
    vim.keymap.set('n', 'zM', ufo.closeAllFolds, { desc = 'Close all folds' })
    vim.keymap.set('n', 'zK', function()
      local winid = ufo.peekFoldedLinesUnderCursor()
      if not winid then
        vim.lsp.buf.hover()
      end
    end, { desc = 'Peek fold' })

    ufo.setup {
      provider_selector = function(bufnr, filetype, buftype)
        -- Use indent provider specifically for yml files
        if filetype == 'yaml' or filetype == 'yml' then
          return 'indent'
        end
        -- For other filetypes, use default providers
        return { 'lsp', 'indent' }
      end,
    }
  end,
}
