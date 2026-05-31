-- preview.nvim: render the current buffer with an external previewer/renderer.
--
-- How it works (see the upstream source): a *previewer* is a command that takes
-- the buffer on stdin and emits rendered bytes on stdout; a *renderer* then
-- displays those bytes. `previewers_by_ft` maps a filetype to {name, renderer},
-- where `name` resolves to a predefined previewer (lua/preview/previewers/*) or,
-- if no predefined one matches, to a definition we supply in `previewers`.
--
-- This config deviates from the upstream README example on purpose: the example
-- assumes pdfroff/wkhtmltopdf/zathura/feh and a local plantuml jar, none of
-- which are installed here. What we actually have: pandoc, groff (+gropdf),
-- curl, xxd, a browser via xdg-open, and a PlantUML server on :8080. So:
--   markdown -> pandoc to standalone HTML -> browser
--   groff    -> groff_ms_pdf (works as-is) -> browser
--   plantuml -> curl the :8080 server (hex transcoding) -> browser
--
-- N.B. The `command` renderer launches the viewer exactly once (it guards on a
-- `started` flag); with render_on_write = true, later saves silently overwrite
-- the temp file but do NOT reload the tab. Refresh the browser to see updates.
return {
  'https://gitlab.com/itaranto/preview.nvim',
  version = '*',
  -- Lazy-load on the filetypes we render and on the command/keymap. FileType
  -- fires before BufWritePost, so the render_on_write autocmd is armed in time.
  ft = { 'markdown', 'groff', 'plantuml' },
  cmd = 'PreviewFile',
  keys = {
    { '<localleader>p', '<cmd>PreviewFile<cr>', desc = 'Preview: render current file' },
  },
  opts = {
    previewers_by_ft = {
      -- pandoc has no usable PDF engine here (pdfroff and wkhtmltopdf are both
      -- missing), so we route markdown through HTML instead of the predefined
      -- pandoc_pdfroff previewer. ext = 'html' makes xdg-open hand the temp file
      -- to the browser as HTML rather than as text/plain.
      markdown = {
        name = 'pandoc_html',
        renderer = { type = 'command', opts = { cmd = { 'xdg-open' }, ext = 'html' } },
      },

      -- groff_ms_pdf is the stock previewer (`groff -Tpdf`); groff + gropdf are
      -- installed so it works untouched. Only the viewer changed: no zathura, so
      -- xdg-open (Chrome is the registered application/pdf handler) opens it.
      groff = {
        name = 'groff_ms_pdf',
        renderer = { type = 'command', opts = { cmd = { 'xdg-open' }, ext = 'pdf' } },
      },

      -- No local `plantuml` binary, but a PlantUML server is up on :8080. The
      -- `~h` prefix tells the server the path is hex-encoded raw source, which
      -- sidesteps PlantUML's deflate codec: we just hex the buffer with xxd.
      -- Caveat: this is a GET, so very large diagrams can hit URL-length limits.
      --
      -- We ask the server for a PNG (/png) and display it in a split via the
      -- `image_nvim` renderer (image.nvim + ghostty's kitty graphics through
      -- tmux). Unlike the ASCII (/txt) backend, the graphical backend supports
      -- the full diagram (notes, skinparam, composition); /txt throws server
      -- side 500s on `note` blocks. The server also returns HTTP 200 for PNG
      -- even on diagram errors (rendered as an error image), so curl -f never
      -- trips. ext = 'png' makes image.nvim treat the temp file as a PNG.
      plantuml = {
        name = 'plantuml_server_png',
        renderer = { type = 'image_nvim', opts = { ext = 'png', split_cmd = 'vsplit' } },
      },
    },

    -- Custom previewer definitions. Keys not matching a predefined previewer are
    -- taken verbatim from here (the upstream loader deep-merges them in).
    previewers = {
      pandoc_html = {
        command = 'pandoc',
        args = { '--from', 'markdown', '--to', 'html', '--standalone', '--output', '-' },
        stdin = true,
        stdout = true,
      },

      -- xxd reads the buffer from stdin (the subshell inherits sh's stdin), and
      -- curl asks the server for a PNG. Swap /png for /txt (buffer renderer) for
      -- ASCII, or /svg (command renderer) to open it in a browser.
      plantuml_server_png = {
        command = 'sh',
        args = { '-c', [[curl -sf "http://localhost:8080/png/~h$(xxd -p | tr -d '\n')"]] },
        stdin = true,
        stdout = true,
      },
    },

    -- Re-render on every :w. The autocmd is buffer-content driven, so it only
    -- fires the previewer for the filetypes mapped above.
    render_on_write = true,
  },
}
