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
-- virtual grids and left the bytes alone), it rewrites the buffer text. So the
-- format-on-open pass below genuinely edits ragged tables and writes the
-- result back to disk (normalize-on-open), rather than just showing it.

-- Align every table in the current buffer on open, then persist the result if
-- it changed anything. The plugin only exposes a format-the-table-at-cursor
-- function, so walk each `|`-block and format it.
local function format_and_save_tables()
  local ok, mtm = pcall(require, 'markdown-table-mode')
  if not ok then
    return
  end
  -- Only touch real, writable, on-disk file buffers: skip picker previews,
  -- scratch/help/terminal buffers, readonly, and unnamed ones so previewing a
  -- markdown file never rewrites it out from under us.
  if vim.bo.buftype ~= '' or not vim.bo.modifiable or vim.bo.readonly then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' or vim.fn.filereadable(name) == 0 then
    return
  end

  local orig = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local view = vim.fn.winsaveview()

  -- Aligning rewrites buffer text, and any edit lands in the undo history: a
  -- stray `u` right after opening would revert the tables to ragged. Drop
  -- 'undolevels' to -1 so this synthetic open-time pass isn't recorded as an
  -- undoable change, then restore it. (The `|`/InsertLeave edits you make
  -- yourself stay fully undoable; only this pass is hidden.)
  local undolevels = vim.bo.undolevels
  vim.bo.undolevels = -1

  -- Alignment never adds or removes rows, so the line count (and thus the
  -- table-block boundaries detected from `orig`) stays stable as we go.
  local lnum, total = 1, #orig
  while lnum <= total do
    if orig[lnum]:match('^%s*|') then
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      pcall(mtm.format_markdown_table)
      lnum = lnum + 1
      while lnum <= total and orig[lnum]:match('^%s*|') do
        lnum = lnum + 1
      end
    else
      lnum = lnum + 1
    end
  end

  vim.bo.undolevels = undolevels
  vim.fn.winrestview(view)

  -- Persist only when alignment actually changed something, so already-aligned
  -- files are never rewritten (no spurious git churn or mtime bumps). Ragged
  -- files get normalized and saved.
  if vim.deep_equal(orig, vim.api.nvim_buf_get_lines(buf, 0, -1, false)) then
    vim.bo.modified = false
  else
    vim.cmd('silent keepjumps write')
  end
end

return {
  'Kicamon/markdown-table-mode.nvim',
  ft = 'markdown',
  config = function()
    require('markdown-table-mode').setup({
      options = {
        insert = true, -- reflow when typing `|`
        insert_leave = true, -- reflow on leaving insert
      },
    })
    -- The plugin ships off (mtm_startup = false, init.lua) and exposes no
    -- opt to start armed; its `:Mtm` toggle is the only lever, and its own
    -- BufEnter/BufLeave hooks keep it live per buffer only once flipped on.
    -- So arm it once here, else you'd `:Mtm` every session before tables
    -- align. `silent!` swallows the toggle's startup "on" notification.
    vim.cmd('silent! Mtm')

    -- Normalize existing tables when a markdown file is opened. BufReadPost
    -- covers files opened after this plugin loaded; the current buffer (whose
    -- FileType is what lazy-loaded us, so its BufReadPost already fired) is
    -- handled by the scheduled call. Both defer the work (and the write) to
    -- after the read settles.
    vim.api.nvim_create_autocmd('BufReadPost', {
      group = vim.api.nvim_create_augroup('mtm_format_on_open', { clear = true }),
      pattern = '*.md',
      callback = function()
        vim.schedule(format_and_save_tables)
      end,
    })
    vim.schedule(format_and_save_tables)
  end,
}
