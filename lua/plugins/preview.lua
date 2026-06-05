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
-- curl, xxd, a browser via the OS default handler, and a PlantUML server on
-- :8080. So:
--   markdown -> pandoc to standalone HTML -> browser
--   groff    -> groff_ms_pdf (works as-is) -> browser
--   plantuml -> curl the :8080 server (hex transcoding) -> browser
--
-- N.B. The `command` renderer launches the viewer exactly once (it guards on a
-- `started` flag); with render_on_write = true, later saves silently overwrite
-- the temp file but do NOT reload the tab. Refresh the browser to see updates.

-- "Open in the default handler" is platform-specific (open / xdg-open / start);
-- reuse the same resolver gx uses rather than hardcoding xdg-open, which only
-- exists on Linux and ENOENTs everywhere else.
local open_cmd = require('url-opener').cmd()

return {
  'https://gitlab.com/itaranto/preview.nvim',
  version = '*',
  -- Lazy-load on the filetypes we render and on the command/keymap. FileType
  -- fires before BufWritePost, so the render_on_write autocmd is armed in time.
  ft = { 'markdown', 'groff', 'plantuml' },
  cmd = 'PreviewFile',
  keys = {
    { '<localleader>p', '<cmd>PreviewFile<cr>', desc = 'Preview: render current file' },
    -- Collapse to a single window first, then render: image.nvim sizes the image
    -- at render time and does not rescale when the window resizes, so clearing
    -- stale splits and re-rendering is the reliable way to get a maximized view.
    {
      '<localleader>P',
      function()
        vim.cmd.only()
        vim.cmd.PreviewFile()
      end,
      ft = 'plantuml',
      desc = 'Preview: render maximized (single window first)',
    },
  },
  opts = {
    previewers_by_ft = {
      -- pandoc has no usable PDF engine here (pdfroff and wkhtmltopdf are both
      -- missing), so we route markdown through HTML instead of the predefined
      -- pandoc_pdfroff previewer. ext = 'html' makes the handler hand the temp
      -- file to the browser as HTML rather than as text/plain.
      markdown = {
        name = 'pandoc_html',
        renderer = { type = 'command', opts = { cmd = open_cmd, ext = 'html' } },
      },

      -- groff_ms_pdf is the stock previewer (`groff -Tpdf`); groff + gropdf are
      -- installed so it works untouched. Only the viewer changed: no zathura, so
      -- the OS default handler (Chrome is the registered application/pdf one) opens it.
      groff = {
        name = 'groff_ms_pdf',
        renderer = { type = 'command', opts = { cmd = open_cmd, ext = 'pdf' } },
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
      -- side 500s on `note` blocks. The server also returns HTTP 200 for SVG
      -- even on diagram errors (rendered as an error image), so curl -f never
      -- trips.
      --
      -- We fetch SVG (not PNG) and let image.nvim rasterize it via librsvg
      -- (ImageMagick's svg delegate) at the size it actually needs: the kitty
      -- protocol only draws raster, so SVG buys us on-demand rasterization that
      -- stays crisp at any window size, instead of upscaling a fixed-res PNG.
      -- ext = 'svg' is what tells image.nvim to run it through that delegate.
      --
      -- split_cmd is a vertical split, so the source stays visible beside the
      -- render. image.nvim fits the image to the window preserving aspect ratio;
      -- since the window is the only size knob, <localleader>P collapses to a
      -- single window first and re-renders for a bigger view. (A horizontal
      -- 'botright split' gives wide diagrams more width, but stacks the panes.)
      plantuml = {
        name = 'plantuml_server_svg',
        renderer = { type = 'image_nvim', opts = { ext = 'svg', split_cmd = 'vsplit' } },
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
      -- curl asks the server for SVG. Swap /svg for /png (also image_nvim) or
      -- /txt (buffer renderer, ASCII; but it 500s on note blocks).
      --
      -- Fail gracefully when the server is down: `curl -sf` exits non-zero on a
      -- refused connection (7) or HTTP error (22), and the plugin turns any
      -- non-zero previewer exit into a hard assert in a vim.system callback (see
      -- preview/job.lua) which surfaces as a scheduled-callback traceback. So we
      -- catch the failure (`|| svg=...`) and substitute a small valid SVG that
      -- says what went wrong; image.nvim renders that in the preview pane and the
      -- command still exits 0, so no traceback. (We keep `-f` so HTTP 500s from a
      -- live-but-unhappy server also fall back instead of rendering an error PNG.)
      plantuml_server_svg = {
        command = 'sh',
        args = {
          '-c',
          [[hex=$(xxd -p | tr -d '\n'); ]]
            .. [[svg=$(curl -sf "http://localhost:8080/svg/~h$hex") || ]]
            .. [[svg='<svg xmlns="http://www.w3.org/2000/svg" width="520" height="96">]]
            .. [[<rect width="100%" height="100%" fill="#1e1e1e"/>]]
            .. [[<text x="16" y="40" font-family="monospace" font-size="15" fill="#e06c75">PlantUML server unavailable</text>]]
            .. [[<text x="16" y="66" font-family="monospace" font-size="12" fill="#888888">expected at http://localhost:8080</text>]]
            .. [[</svg>'; ]]
            .. [[printf '%s' "$svg"]],
        },
        stdin = true,
        stdout = true,
      },
    },

    -- Re-render on every :w. The autocmd is buffer-content driven, so it only
    -- fires the previewer for the filetypes mapped above.
    render_on_write = true,
  },
}
