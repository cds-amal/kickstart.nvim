-- render-markdown.nvim arrives as a dependency of the Solana course plugin
-- (see solana-course.lua); this spec carries its config and a per-buffer
-- comment toggle.
--
-- The plugin conceals HTML comments (<!-- ... -->) by default and only
-- un-conceals the line under the cursor, so speaker-note blocks vanish the
-- moment the cursor leaves them. Rather than flip the global default, ,tc
-- reveals comments in the current buffer alone.
--
-- There's no public per-buffer config API: state.get() builds a buffer's
-- config once and reuses it across every re-render, so the toggle clears that
-- cache entry and re-renders with a custom comment.conceal override. A reach
-- into internals, but it's the only lever that scopes the override to one
-- buffer without calling setup() (which is global and wipes every buffer's
-- cache).
local function toggle_comments(buf)
  local state = require('render-markdown.state')
  local show = not vim.b[buf].rm_comments_shown
  vim.b[buf].rm_comments_shown = show
  state.cache[buf] = nil
  require('render-markdown.api').render({
    buf = buf,
    config = show and { html = { comment = { conceal = false } } } or nil,
  })
  vim.notify('render-markdown: HTML comments ' .. (show and 'shown' or 'concealed'), vim.log.levels.INFO)
end

return {
  'MeanderingProgrammer/render-markdown.nvim',
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      group = vim.api.nvim_create_augroup('render_markdown_comment_toggle', { clear = true }),
      callback = function(ev)
        vim.keymap.set('n', '<leader>tc', function()
          toggle_comments(ev.buf)
        end, { buffer = ev.buf, desc = '[t]oggle HTML [c]omment conceal (this buffer)' })
      end,
    })
  end,
}
