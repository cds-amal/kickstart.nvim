-- markdown-table-mode.nvim: live table alignment for markdown.
--
-- touchup (plugins/touchup.lua) deliberately has no table feature, so pipe
-- tables would otherwise sit unaligned. This keeps them plain text (no grid,
-- no conceal: source stays == display, matching touchup's philosophy) and
-- reflows the columns as you type `|` or leave insert mode.
--
-- Complements the existing `,tm` map (plugins/tabular.lua), which is a manual
-- one-shot TSV-to-table align; this one is the continuous auto-align.
--
-- N.B. this is a formatter, not a renderer: unlike render-markdown (which drew
-- virtual grids and left the bytes alone), it rewrites the buffer text. It
-- only does so in response to your own edits (`|` in insert mode, InsertLeave),
-- and those land in the undo history like any other change; opening a file
-- leaves its tables, and the file on disk, exactly as they were.

return {
  -- 'Kicamon/markdown-table-mode.nvim',
  dir = '~/dev/nvim-plugins/md-table-mode.nvim/',
  ft = 'markdown',
  config = function()
    require('markdown-table-mode').setup {
      filetype = { '*.md', '*.markdown', '*.tla' },
      options = {
        insert = true, -- reflow when typing `|`
        insert_leave = true, -- reflow on leaving insert
        auto_start = true, -- arm matching buffers as they open
      },
    }
  end,
}
