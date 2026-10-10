-- markdown-table-mode.nvim: live table alignment for markdown.
--
-- touchup (plugins/touchup.lua) deliberately has no table feature, so pipe
-- tables would otherwise sit unaligned. This keeps them plain text (no grid,
-- no conceal: source stays == display, matching touchup's philosophy) and
-- reflows the columns as you type `|` or leave insert mode.
--
-- The plugin also carries the one-shot align: align the block around the
-- cursor on the separator under it, or fill the gaps with a typed character
-- (dot leaders). The plugin default for the spaced align is `,Tt`, which here
-- is <leader>Tt and collides with truth-table's global TruthTableToggle, so
-- this config rebinds it to `,Ta`; `,TT` is free in truth-table's table
-- family and keeps its default. The maps are global, so the spec lists them
-- as lazy triggers; pressing one anywhere loads the plugin and replays the
-- key.
--
-- N.B. this is a formatter, not a renderer: unlike render-markdown (which drew
-- virtual grids and left the bytes alone), it rewrites the buffer text. It
-- only does so in response to your own edits (`|` in insert mode, InsertLeave),
-- and those land in the undo history like any other change; opening a file
-- leaves its tables, and the file on disk, exactly as they were.

return {
  -- 'Kicamon/markdown-table-mode.nvim',
  dir = '~/dev/nvim-plugins/md-table-mode.nvim/',
  ft = { 'markdown', 'tla' },
  keys = { ',Ta', ',TT' },
  config = function()
    require('markdown-table-mode').setup {
      filetype = { '*.md', '*.markdown', '*.tla' },
      options = {
        insert = true, -- reflow when typing `|`
        insert_leave = true, -- reflow on leaving insert
        auto_start = true, -- arm matching buffers as they open
        tabularize = ',Ta', -- default ,Tt is truth-table's toggle here
        tabularize_fill = ',TT',
      },
    }
  end,
}
